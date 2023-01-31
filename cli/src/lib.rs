use std::{
    io::{BufRead, Write},
    path::PathBuf,
};

use helpers::{ensure_binaries_installed, get_arch, get_install_path, get_os, kind_cluster};

#[derive(clap::Parser)]
pub struct CliArgs {
    #[command(subcommand)]
    cli_action: CliAction,
}

pub struct ProgramArgs<'a> {
    pub cli_args: CliArgs,
    pub kube_client_factory: Box<dyn Fn() -> kube_client::Client>,
    pub stderr: &'a mut dyn Write,
    pub _stdin: &'a dyn BufRead,
    pub _stdout: &'a mut dyn Write,
    pub dir_parent: Option<PathBuf>,
    pub raw_arch: String,
    pub raw_os: String,
    pub kind_stub: String,
    pub kubectl_stub: String,
}

#[derive(clap::Subcommand)]
enum CliAction {
    Create {
        #[clap(long)]
        forward_postgres: Option<Option<String>>,
        #[clap(long, default_value_t = false)]
        sync: bool,
    },
    Start {
        #[clap(long)]
        forward_postgres: Option<Option<String>>,
        /// optional, positional customer id
        id: Option<String>,

        #[clap(long, default_value_t = false)]
        overwrite_resources: bool,
    },
}

pub mod errors {
    use std::{error::Error, fmt};

    #[derive(Debug)]
    pub(crate) struct KindClusterInstallError(String);

    impl fmt::Display for KindClusterInstallError {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            write!(f, "Error installing kind cluster: {}", self.0)
        }
    }

    impl Error for KindClusterInstallError {}

    impl KindClusterInstallError {
        pub fn new(output: String) -> KindClusterInstallError {
            Self(output)
        }
    }

    #[derive(Debug)]
    pub(crate) struct KindClusterGetError(String);

    impl fmt::Display for KindClusterGetError {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            write!(f, "Error getting kind cluster: {}", self.0)
        }
    }

    impl Error for KindClusterGetError {}

    impl KindClusterGetError {
        pub fn new(output: String) -> KindClusterGetError {
            Self(output)
        }
    }
}

pub mod prod {
    pub const URL_STUB_KIND: &str =
        "https://github.com/kubernetes-sigs/kind/releases/download/v0.17.0";
    pub const URL_STUB_KUBECTL: &str = "https://dl.k8s.io/release/v1.25.4/bin";
}

mod konstants {
    pub static DEFAULT_POSTGRES_FWD_TGT: &str = "battery-base/pg-control";
    pub static NOT_IMPL: &str = "Not yet implemented";
    pub const LINUX: &str = "linux";
    pub const DARWIN: &str = "darwin";
    pub const MACOS: &str = "macos";
    pub const AARCH64: &str = "aarch64";
    pub const AMD64: &str = "amd64";
    pub const ARM64: &str = "arm64";
    pub const X86_64: &str = "x86_64";
}

mod helpers {
    use crate::errors;
    use k8s_openapi::api::core::v1::Pod;
    use kube_client::{api::ListParams, Api};
    use std::{
        io::Read,
        os::unix::prelude::PermissionsExt,
        path::{Path, PathBuf},
    };

    use crate::konstants;

    pub(crate) fn forward_postgres_handle(fwd_postgres_opt: &Option<Option<String>>) -> String {
        let fwd_postgres = match fwd_postgres_opt {
            None => "".to_string(),
            Some(None) => konstants::DEFAULT_POSTGRES_FWD_TGT.to_string(),
            Some(Some(tgt_opt)) => tgt_opt.trim().to_string(),
        };
        fwd_postgres
    }

    pub(crate) async fn get_pg_control_primary(
        client: kube_client::Client,
        cluster: &str,
        namespace: &str,
    ) -> Result<String, Box<dyn std::error::Error>> {
        let pods: Api<Pod> = Api::namespaced(client, namespace);
        let lp = ListParams::default().labels(&format!("spilo-role=master,cluster-name={cluster}"));
        let results = pods.list(&lp).await?;
        let pod = results.iter().next();
        match pod.map(|x| x.metadata.name.as_ref().unwrap().to_string()) {
            Some(p) => Ok(p),
            None => Err("Pod doesn't have `name` attribute".into()),
        }
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
                        std::fs::File::open(Path::new(fetch_url.path()))?
                            .read_to_string(&mut buf)?;
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
        let kubectl_url =
            url::Url::parse(vec![kubectl_stub, os, arch, "kubectl"].join("/").as_str())?;
        validate_or_fetch_bin(kubectl_path, kubectl_url).await?;
        Ok(())
    }

    pub(crate) fn kind_cluster(
        kind_bin: &Path,
        cluster_name: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let install_out = std::process::Command::new(kind_bin)
            .args(["create", "cluster", "--name", cluster_name])
            .output()?;
        match install_out.status.success() {
            false => {
                return Err(Box::new(errors::KindClusterInstallError::new(format!(
                    "\n\nSTDOUT: {}\n\nSTDERR: {}\n\n",
                    std::str::from_utf8(&install_out.stdout)?,
                    std::str::from_utf8(&install_out.stderr)?,
                ))));
            }
            true => {
                let get_out = std::process::Command::new(kind_bin)
                    .args(["get", "kubeconfig", "--name", cluster_name])
                    .output()?;
                match get_out.status.success() {
                    false => {
                        return Err(Box::new(errors::KindClusterGetError::new(format!(
                            "\n\nSTDOUT: {}\n\nSTDERR: {}\n\n",
                            std::str::from_utf8(&get_out.stdout)?,
                            std::str::from_utf8(&get_out.stderr)?
                        ))));
                    }
                    true => Ok(()),
                }
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use clap::Parser;
    use hyper::Body;
    use k8s_openapi::http::{Request, Response};
    use url::Url;

    use crate::konstants;
    use crate::program_main;
    use crate::CliArgs;
    use crate::ProgramArgs;

    use tower_test::mock;

    use std::fs;
    use std::io::Write;
    use std::os::unix::prelude::OpenOptionsExt;

    mod fixtures {
        pub(crate) static DUMMY_KIND_SUCCEDS: &[u8; 22] = b"#!/bin/bash

exit 0;

";
    }

    #[tokio::test]
    async fn test_empty_parent_dir() {
        let mut err = Vec::new();
        let mut out = Vec::new();
        let input = "".as_bytes();
        let mut program_args = ProgramArgs {
            cli_args: CliArgs::parse_from(["cli", "create"]),
            kube_client_factory: Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                kube_client::Client::new(mock_service, "default")
            }),
            stderr: &mut err,
            _stdin: &input,
            _stdout: &mut out,
            dir_parent: None,
            raw_arch: String::from("x86_64"),
            raw_os: String::from("linux"),
            kind_stub: String::from("foo"),
            kubectl_stub: String::from("bar"),
        };
        let rc = program_main(&mut program_args).await;
        assert_eq!(rc, exitcode::CANTCREAT);
        assert_eq!(
            String::from_utf8(err).unwrap(),
            "Error: expected user homedir, got None\n"
        );
        assert_eq!(String::from_utf8(out).unwrap(), "");
    }

    #[tokio::test]
    async fn test_invalid_arch_fails() {
        let mut err = Vec::new();
        let mut out = Vec::new();
        let input = "".as_bytes();
        let tmp = tempdir::TempDir::new("test_invalid_arch_fails").unwrap();
        let kind_stub: String = Url::from_file_path(tmp.path()).unwrap().into();
        let kubectl_stub: String = Url::from_file_path(tmp.path()).unwrap().into();
        let mut program_args = ProgramArgs {
            cli_args: CliArgs::parse_from(["cli", "create"]),
            kube_client_factory: Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                kube_client::Client::new(mock_service, "default")
            }),
            stderr: &mut err,
            _stdin: &input,
            _stdout: &mut out,
            dir_parent: Some(tmp.into_path()),
            raw_arch: String::from("sparc64"),
            raw_os: String::from("linux"),
            kind_stub,
            kubectl_stub,
        };
        let rc = program_main(&mut program_args).await;
        assert_eq!(rc, exitcode::OSERR);
        assert_eq!(
            String::from_utf8(err).unwrap(),
            "Error: architecture `sparc64` is not supported\n"
        );
        assert_eq!(String::from_utf8(out).unwrap(), "");
    }

    #[tokio::test]
    async fn test_invalid_os_fails() {
        let mut err = Vec::new();
        let mut out = Vec::new();
        let input = "".as_bytes();
        let tmp = tempdir::TempDir::new("test_invalid_arch_fails").unwrap();
        let kind_stub = Url::from_file_path(tmp.path()).unwrap().to_string();
        let kubectl_stub = Url::from_file_path(tmp.path()).unwrap().to_string();
        let mut program_args = ProgramArgs {
            cli_args: CliArgs::parse_from(["cli", "create"]),
            kube_client_factory: Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                kube_client::Client::new(mock_service, "default")
            }),
            stderr: &mut err,
            _stdin: &input,
            _stdout: &mut out,
            dir_parent: Some(tmp.into_path()),
            raw_arch: String::from("amd64"),
            raw_os: String::from("freebsd"),
            kind_stub,
            kubectl_stub,
        };
        let rc = program_main(&mut program_args).await;
        assert_eq!(rc, exitcode::OSERR);
        assert_eq!(
            String::from_utf8(err).unwrap(),
            "Error: OS `freebsd` is not supported\n"
        );
        assert_eq!(String::from_utf8(out).unwrap(), "");
    }

    #[tokio::test]
    async fn test_blank() {
        let mut err = Vec::new();
        let mut out = Vec::new();
        let input = "".as_bytes();
        let tmp = tempdir::TempDir::new("test_blank").unwrap();
        fs::OpenOptions::new()
            .create(true)
            .write(true)
            .mode(0o755)
            .open(tmp.path().join("kind-linux-amd64"))
            .unwrap()
            .write_all(fixtures::DUMMY_KIND_SUCCEDS)
            .unwrap();
        std::fs::create_dir_all(vec![tmp.path().to_str().unwrap(), "linux", "amd64"].join("/"))
            .unwrap();
        fs::OpenOptions::new()
            .create(true)
            .write(true)
            .mode(0o755)
            .open(vec![tmp.path().to_str().unwrap(), "linux", "amd64", "kubectl"].join("/"))
            .unwrap();

        let kind_stub = Url::from_file_path(&tmp).unwrap().to_string();
        let kubectl_stub = Url::from_file_path(&tmp).unwrap().to_string();
        let mut program_args = ProgramArgs {
            cli_args: CliArgs::parse_from(["cli", "create"]),
            kube_client_factory: Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                kube_client::Client::new(mock_service, "default")
            }),
            stderr: &mut err,
            _stdin: &input,
            _stdout: &mut out,
            dir_parent: Some(tmp.into_path()),
            raw_arch: String::from("x86_64"),
            raw_os: String::from("linux"),
            kind_stub,
            kubectl_stub,
        };
        let rc = program_main(&mut program_args).await;
        assert_eq!(rc, exitcode::UNAVAILABLE);
        assert_eq!(
            String::from_utf8(err).unwrap(),
            format!("{}: create\n", konstants::NOT_IMPL)
        );
        assert_eq!(String::from_utf8(out).unwrap(), "");
    }
}

fn log(stderr: &mut dyn Write, msg: &str) {
    write!(stderr, "{msg}").unwrap();
}

pub async fn program_main<'a>(args: &mut ProgramArgs<'_>) -> exitcode::ExitCode {
    let install_dir = match &args.dir_parent {
        Some(x) => get_install_path(x),
        None => {
            log(args.stderr, "Error: expected user homedir, got None\n");
            return exitcode::CANTCREAT;
        }
    };
    let arch = match get_arch(&args.raw_arch) {
        Some(x) => x,
        None => {
            log(
                args.stderr,
                &format!("Error: architecture `{}` is not supported\n", args.raw_arch),
            );
            return exitcode::OSERR;
        }
    };
    let os = match get_os(&args.raw_os) {
        Some(x) => x,
        None => {
            log(
                args.stderr,
                &format!("Error: OS `{}` is not supported\n", args.raw_os),
            );
            return exitcode::OSERR;
        }
    };
    match ensure_binaries_installed(
        install_dir.as_path(),
        arch,
        os,
        &args.kind_stub,
        &args.kubectl_stub,
    )
    .await
    {
        Ok(_) => {}
        Err(e) => {
            log(
                args.stderr,
                &format!("Error: problem installing tools\nMessage: `{e}`"),
            );
            return exitcode::TEMPFAIL;
        }
    };

    // start kind cluster
    let mut kind_path = install_dir;
    kind_path.push("kind");

    // TODO: change hardcoded cluster name
    match kind_cluster(&kind_path, "battery") {
        Err(e) => {
            log(args.stderr, &e.to_string());
            return exitcode::SOFTWARE;
        }
        Ok(_) => ..,
    };

    let client = (args.kube_client_factory)();
    match &args.cli_args.cli_action {
        CliAction::Create {
            ref forward_postgres,
            sync,
        } => {
            let _fwd_postgres_tgt: &String = &helpers::forward_postgres_handle(forward_postgres);
            if *sync {
                log(args.stderr, "sync: true\n");
            }

            log(args.stderr, &format!("{}: create\n", konstants::NOT_IMPL));
            exitcode::UNAVAILABLE
        }
        CliAction::Start {
            forward_postgres,
            id,
            overwrite_resources,
        } => {
            let id_tgt: String = match id {
                None => "demo".to_string(),
                Some(tgt) => tgt.to_string(),
            };
            if *overwrite_resources {
                log(args.stderr, "overwrite-resources: true\n");
            }
            log(args.stderr, &format!("id: {id_tgt}\n"));
            log(args.stderr, &format!("{}: start\n", konstants::NOT_IMPL));
            let fwd_postgres_tgt = helpers::forward_postgres_handle(forward_postgres);
            if !(fwd_postgres_tgt.is_empty()) {
                let (namespace, cluster) = fwd_postgres_tgt.split_once('/').unwrap();
                match helpers::get_pg_control_primary(client, cluster, namespace).await {
                    Ok(p) => log(args.stderr, &format!("{p}\n")),
                    Err(e) => {
                        log(args.stderr, &format!("Error: {e}\n"));
                        return exitcode::TEMPFAIL;
                    }
                };
            }
            exitcode::UNAVAILABLE
        }
    }
}
