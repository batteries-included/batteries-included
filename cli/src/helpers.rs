use crate::errors;
use k8s_openapi::api::core::v1::Pod;
use kube_client::{api::ListParams, Api};
use retry::delay::Fixed;
use serde_json::{from_str, Value};
use signal_hook::flag;
use std::{
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
    match retry::retry(Fixed::from_millis(10000).take(100), || {
        let pods: Api<Pod> = Api::namespaced(client_factory(), namespace);
        let lp = ListParams::default().labels(&format!("spilo-role=master,cluster-name={cluster}"));
        let results = futures::executor::block_on(pods.list(&lp)).unwrap();
        let pod = results.iter().next();
        match pod.map(|x| x.metadata.name.as_ref().unwrap().to_string()) {
            Some(name) => Ok(name),
            None => {
                eprintln!("waiting for pod to come up...");
                Err(format!(
                        "Failed to get pg control primary for cluster {cluster} in namespace {namespace}"
                ))
            }
        }
    }) {
        Ok(name) => Ok(name),
        Err(e) => Err(e.to_string().into()),
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
    flag::register(signal_hook::consts::SIGTERM, Arc::clone(&should_terminate)).unwrap();
    let mut pg_control_primary = get_pg_control_primary(client_factory, cluster, namespace).await?;
    // TODO: change this to use the native client instead of kubectl
    let mut proc = async_process::Command::new(&kubectl_path)
        .args([
            "port-forward",
            &format!("pods/{pg_control_primary}"),
            &format!("{port}:{port}"),
            "-n",
            namespace,
            "--address",
            "0.0.0.0",
        ])
        .spawn()?;

    while !should_terminate.load(Ordering::Relaxed) {
        match proc.try_status()? {
            None => {}
            Some(_) => {
                pg_control_primary =
                    get_pg_control_primary(client_factory, cluster, namespace).await?;
                proc = async_process::Command::new(&kubectl_path)
                    .args([
                        "port-forward",
                        &format!("pods/{pg_control_primary}"),
                        &format!("{port}:{port}"),
                        "-n",
                        namespace,
                        "--address",
                        "0.0.0.0",
                    ])
                    .spawn()?;
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
            std::fs::create_dir_all(bin_path.parent().unwrap())?;
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

pub(crate) fn apply_resources(
    kubectl_path: &Path,
    json_blob: &str,
) -> Result<(), retry::Error<String>> {
    let data: Value = from_str(json_blob).unwrap();
    let tmp = tempdir::TempDir::new("custom_resources").unwrap();
    for (i, (_k, v)) in data["initial_resource"]
        .as_object()
        .unwrap()
        .into_iter()
        .enumerate()
    {
        fs::write(
            vec![tmp.as_ref().to_str().unwrap(), &format!("{i}.json")].join("/"),
            v.to_string(),
        )
        .unwrap();
    }
    retry::retry(Fixed::from_millis(10000).take(50), || {
        let lkubectl = PathBuf::from(kubectl_path);
        match std::process::Command::new(lkubectl)
            .args(["apply", "-f", tmp.as_ref().to_str().unwrap(), "-R"])
            .status()
        {
            Ok(status) => match status.success() {
                true => Ok(()),
                false => Err(status.to_string()),
            },
            Err(e) => Err(e.to_string()),
        }
    })
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
        false => {
            return Err(Box::new(errors::KindClusterError::new(format!(
                "\n\nInstall STDOUT: {}\n\nInstall STDERR: {}\n\nGet STDOUT {}\n\nGet STDERR: {}\n",
                std::str::from_utf8(&install_out.stdout)?,
                std::str::from_utf8(&install_out.stderr)?,
                std::str::from_utf8(&get_out.stdout)?,
                std::str::from_utf8(&get_out.stderr)?
            ))));
        }
        true => Ok(()),
    }
}
