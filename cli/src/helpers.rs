use crate::errors;
use async_process::Child;
use k8s_openapi::api::core::v1::Pod;
use kube_client::{api::ListParams, Api};
use retry::delay::Fixed;
use serde_json::{from_str, Value};
use signal_hook::flag;
use std::{
    error::Error,
    fs::{self, OpenOptions},
    io::{Read, Write},
    os::unix::prelude::PermissionsExt,
    path::{Path, PathBuf},
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    thread,
};

use crate::konstants;

pub fn forward_postgres_handle(fwd_postgres_opt: &Option<Option<String>>) -> String {
    let fwd_postgres = match fwd_postgres_opt {
        None => "".to_string(),
        Some(None) => konstants::DEFAULT_POSTGRES_FWD_TGT.to_string(),
        Some(Some(tgt_opt)) => tgt_opt.trim().to_string(),
    };
    fwd_postgres
}

pub(crate) async fn get_pg_control_primary(
    client_factory: &dyn Fn() -> kube_client::Client,
    cluster: &str,
    namespace: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    match retry::retry(Fixed::from_millis(1000).take(100), || {
        eprintln!("Getting pg control primary");

        let pods: Api<Pod> = Api::namespaced(client_factory(), namespace);
        let lp = ListParams::default().labels(&format!("spilo-role=master,cluster-name={cluster}"));
        match futures::executor::block_on(pods.list(&lp)) {
            Ok(res) => {
                let pod = res.iter().next();
                match pod.map(|x| x.metadata.name.as_ref().unwrap().to_string()) {
                    Some(name) => Ok(name),
                    None => {
                        println!("waiting for pod to come up...");
                        Err(format!(
                            "Failed to get pg control primary for cluster {cluster} in namespace {namespace}"
                        ))
                    }
                }
            }
            Err(err) => Err(format!("Failed to connect to cluster: {}", err)),
        }
    }) {
        Ok(name) => Ok(name),
        Err(e) => Err(e.to_string().into()),
    }
}

// TODO: change this to use the native client instead of kubectl
async fn launch_port_forward_to_pg_control_process(
    client_factory: &dyn Fn() -> kube_client::Client,
    kubectl_path: &PathBuf,
    cluster: &str,
    namespace: &str,
    port: u16,
) -> Result<Child, Box<dyn Error>> {
    let pg_control_primary = get_pg_control_primary(client_factory, cluster, namespace).await?;
    match async_process::Command::new(kubectl_path)
        .args([
            "port-forward",
            &format!("pods/{pg_control_primary}"),
            &format!("{port}:{port}"),
            "-n",
            namespace,
            "--address",
            "0.0.0.0",
        ])
        .spawn()
    {
        Ok(child) => Ok(child),
        Err(e) => Err(format!("Failed to launch port forward: {}", e).into()),
    }
}

pub(crate) async fn forward_postgres(
    client_factory: &dyn Fn() -> kube_client::Client,
    kubectl_path: PathBuf,
    cluster: &str,
    namespace: &str,
    port: u16,
) -> Result<(), Box<dyn std::error::Error>> {
    let should_terminate = Arc::new(AtomicBool::new(false));
    flag::register(signal_hook::consts::SIGTERM, Arc::clone(&should_terminate))?;
    let mut proc = launch_port_forward_to_pg_control_process(
        client_factory,
        &kubectl_path,
        cluster,
        namespace,
        port,
    )
    .await?;

    while !should_terminate.load(Ordering::Relaxed) {
        match proc.try_status()? {
            None => {}
            Some(_) => {
                // if the connection was dropped, wait to retry
                //
                // TODO: parameterize this, or move to exponential backoff
                thread::sleep(core::time::Duration::from_secs(10));
                proc = launch_port_forward_to_pg_control_process(
                    client_factory,
                    &kubectl_path,
                    cluster,
                    namespace,
                    port,
                )
                .await?;
            }
        }
        thread::sleep(core::time::Duration::from_secs(1));
    }
    proc.kill().expect("could not kill port-forward");
    Ok(())
}

pub(crate) fn get_install_path(parent: &Path) -> PathBuf {
    let mut install_path = std::path::PathBuf::from(parent);
    install_path.push(".batteries/bin");
    install_path
}

pub(crate) fn get_arch(arch: &str) -> Option<&'static str> {
    match arch {
        konstants::AARCH64 => Some(konstants::ARM64),
        konstants::AMD64 => Some(konstants::AMD64),
        konstants::ARM64 => Some(konstants::ARM64),
        konstants::X86_64 => Some(konstants::AMD64),
        _ => None,
    }
}

pub(crate) fn get_os(os: &str) -> Option<&'static str> {
    match os {
        konstants::DARWIN => Some(konstants::DARWIN),
        konstants::LINUX => Some(konstants::LINUX),
        konstants::MACOS => Some(konstants::DARWIN),
        _ => None,
    }
}

async fn validate_or_fetch_bin(
    bin_path: PathBuf,
    fetch_url: url::Url,
) -> Result<(), Box<dyn std::error::Error>> {
    let res = match bin_path.exists() {
        true => Ok(()),
        false => {
            let parent_dir: Result<&Path, Box<dyn std::error::Error>> = match bin_path.parent() {
                Some(p) => Ok(p),
                None => {
                    Err(format!("Could not get parent directory for {}", bin_path.display()).into())
                }
            };
            std::fs::create_dir_all(parent_dir?)?;
            let mut dst = std::fs::File::create(&bin_path)?;
            let bytes: Vec<u8> = match fetch_url.scheme() {
                "file" => {
                    let mut buf = String::new();
                    std::fs::File::open(Path::new(fetch_url.path()))?.read_to_string(&mut buf)?;
                    buf.into_bytes()
                }
                "https" => reqwest::get(fetch_url.as_str())
                    .await?
                    .bytes()
                    .await?
                    .to_vec(),
                x => {
                    return Err(format!("Unsupported file scheme: `{x}`").into());
                }
            };
            std::io::copy(&mut bytes.as_slice(), &mut dst)?;
            std::fs::set_permissions(&bin_path, std::fs::Permissions::from_mode(0o755))?;
            Ok(())
        }
    };
    res
}

fn retry_apply(kubectl_path: &str, data_path: &str) -> Result<(), Box<dyn Error>> {
    let res = retry::retry(
        Fixed::from_millis(10000).take(50),
        || match std::process::Command::new(kubectl_path)
            .args(["apply", "-f", data_path, "-R"])
            .status()
        {
            Ok(status) => match status.success() {
                true => Ok(()),
                false => Err(status.to_string()),
            },
            Err(e) => Err(e.to_string()),
        },
    );
    match res {
        Ok(_) => Ok(()),
        Err(e) => Err(format!("Failed to apply resources: {}", e).into()),
    }
}

pub(crate) fn apply_resources(
    kubectl_path: &Path,
    json_blob: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let data: Value = from_str(json_blob)?;
    let tmp = tempdir::TempDir::new("custom_resources")?;
    let tmp_path_str = match tmp.as_ref().to_str() {
        Some(x) => x,
        None => {
            return Err(format!(
                "Could not convert TempDir path to string: {}",
                tmp.path().display()
            )
            .into());
        }
    };
    let kubectl_str = match kubectl_path.to_str() {
        Some(s) => s,
        None => {
            return Err(format!(
                "Could not convert path to string: {}",
                kubectl_path.display()
            )
            .into());
        }
    };
    for (i, (_k, v)) in data["initial_resource"]
        .as_object()
        .unwrap()
        .into_iter()
        .enumerate()
    {
        fs::write(
            vec![tmp.as_ref().to_str().unwrap(), &format!("{i}.json")].join("/"),
            v.to_string(),
        )?;
    }

    retry_apply(kubectl_str, tmp_path_str)
}

pub(crate) async fn ensure_binaries_installed(
    install_dir: &Path,
    arch: &str,
    os: &str,
    kind_stub: &str,
    kubectl_stub: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let kind_path = install_dir.join("kind");
    let kind_url = url::Url::parse(
        vec![kind_stub, &format!("kind-{os}-{arch}")]
            .join("/")
            .as_str(),
    )?;
    validate_or_fetch_bin(kind_path, kind_url).await?;
    let kubectl_path = install_dir.join("kubectl");
    let kubectl_url = url::Url::parse(vec![kubectl_stub, os, arch, "kubectl"].join("/").as_str())?;
    validate_or_fetch_bin(kubectl_path, kubectl_url).await?;
    Ok(())
}

pub(crate) fn kind_cluster(
    kind_bin: &Path,
    cluster_name: &str,
    user_homedir: &Path,
) -> Result<(), Box<dyn std::error::Error>> {
    let install_out = std::process::Command::new(kind_bin)
        .args(["create", "cluster", "--name", cluster_name])
        .output()?;
    let get_out = std::process::Command::new(kind_bin)
        .args(["get", "kubeconfig", "--name", cluster_name])
        .output()?;

    if !(install_out.status.success()) {
        let kube_config_path = user_homedir.join(".kube/config");
        let mut kube_config_f = OpenOptions::new()
            .truncate(true)
            .write(true)
            .open(kube_config_path)?;
        kube_config_f.write_all(&get_out.stdout)?;
    }

    match get_out.status.success() {
        false => Err(Box::new(errors::KindClusterError::new(format!(
            "\n\nInstall STDOUT: {}\n\nInstall STDERR: {}\n\nGet STDOUT {}\n\nGet STDERR: {}\n",
            std::str::from_utf8(&install_out.stdout)?,
            std::str::from_utf8(&install_out.stderr)?,
            std::str::from_utf8(&get_out.stdout)?,
            std::str::from_utf8(&get_out.stderr)?
        )))),
        true => Ok(()),
    }
}
