use std::{
    io::{BufRead, Write},
    path::PathBuf,
};

use helpers::{ensure_binaries_installed, get_arch, get_install_path, get_os};

#[derive(clap::Parser)]
pub struct Args {
    #[command(subcommand)]
    cli_action: CliAction,
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
    use k8s_openapi::api::core::v1::Pod;
    use kube_client::{api::ListParams, Api};
    use std::{
        io::Cursor,
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
        let lp =
            ListParams::default().labels(&format!("spilo-role=master,cluster-name={}", cluster));
        let results = pods.list(&lp).await?;
        let pod = results.iter().next();
        match pod.and_then(|x| Some(x.metadata.name.as_ref().unwrap().to_string())) {
            Some(p) => return Ok(p),
            None => return Err("Pod doesn't have `name` attribute".into()),
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
            konstants::AMD64 => return Some(konstants::AMD64),
            konstants::ARM64 => Some(konstants::ARM64),
            konstants::X86_64 => Some(konstants::AMD64),
            _ => None,
        }
    }

    pub(crate) fn get_os(os: &str) -> Option<&'static str> {
        match os {
            konstants::DARWIN => Some(konstants::DARWIN),
            konstants::LINUX => return Some(konstants::LINUX),
            konstants::MACOS => Some(konstants::DARWIN),
            _ => None,
        }
    }

    async fn validate_or_fetch_bin(
        bin_path: PathBuf,
        fetch_url: url::Url,
    ) -> Result<(), Box<dyn std::error::Error>> {
        match bin_path.exists() {
            true => return Ok(()),
            false => {
                std::fs::create_dir_all(bin_path.parent().unwrap())?;
                match fetch_url.scheme() {
                    "file" => {
                        std::fs::copy(Path::new(fetch_url.path()), &bin_path)?;
                    }
                    "https" => {
                        let mut out = std::fs::File::create(&bin_path).unwrap();
                        let mut content =
                            Cursor::new(reqwest::get(fetch_url.as_str()).await?.bytes().await?);

                        std::io::copy(&mut content, &mut out)?;
                    }
                    x => {
                        return Err(format!("Unsupported file scheme: `{}`", x).into());
                    }
                };
                std::fs::set_permissions(&bin_path, std::fs::Permissions::from_mode(0o755))?;
                return Ok(());
            }
        };
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
            vec![kind_stub, &format!("kind-{}-{}", os, arch)]
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
}

#[cfg(test)]
mod tests {
    use clap::Parser;
    use hyper::Body;
    use k8s_openapi::http::{Request, Response};
    use url::Url;

    use crate::konstants;
    use crate::program_main;
    use crate::Args;

    use tower_test::mock;

    use std::fs;
    use std::os::unix::prelude::OpenOptionsExt;

    #[tokio::test]
    async fn test_empty_parent_dir() {
        let mut err = Vec::new();
        let mut out = Vec::new();
        let input = "".as_bytes();
        let rc = program_main(
            Args::parse_from(["cli", "create"]),
            Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                return kube_client::Client::new(mock_service, "default");
            }),
            &mut err,
            &input,
            &mut out,
            None,
            String::from("x86_64"),
            String::from("linux"),
            String::from("foo"),
            String::from("bar"),
        )
        .await;
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

        let rc = program_main(
            Args::parse_from(["cli", "create"]),
            Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                return kube_client::Client::new(mock_service, "default");
            }),
            &mut err,
            &input,
            &mut out,
            Some(tmp.into_path()),
            String::from("sparc64"),
            String::from("linux"),
            kind_stub,
            kubectl_stub,
        )
        .await;
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
        let rc = program_main(
            Args::parse_from(["cli", "create"]),
            Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                return kube_client::Client::new(mock_service, "default");
            }),
            &mut err,
            &input,
            &mut out,
            Some(tmp.into_path()),
            String::from("amd64"),
            String::from("freebsd"),
            kind_stub,
            kubectl_stub,
        )
        .await;
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
        let rc = program_main(
            Args::parse_from(["cli", "create"]),
            Box::new(|| {
                let (mock_service, _) = mock::pair::<Request<Body>, Response<Body>>();
                return kube_client::Client::new(mock_service, "default");
            }),
            &mut err,
            &input,
            &mut out,
            Some(tmp.into_path()),
            String::from("x86_64"),
            String::from("linux"),
            kind_stub,
            kubectl_stub,
        )
        .await;
        assert_eq!(rc, exitcode::UNAVAILABLE);
        assert_eq!(
            String::from_utf8(err).unwrap(),
            format!("{}: create\n", konstants::NOT_IMPL)
        );
        assert_eq!(String::from_utf8(out).unwrap(), "");
    }
}

fn log(stderr: &mut dyn Write, msg: &str) {
    match write!(stderr, "{}", msg) {
        _ => return,
    }
}

pub async fn program_main<'a>(
    args: Args,
    kube_client_factory: Box<dyn Fn() -> kube_client::Client>,
    stderr: &'a mut dyn Write,
    _stdin: &'a dyn BufRead,
    _stdout: &'a mut dyn Write,
    dir_parent: Option<PathBuf>,
    raw_arch: String,
    raw_os: String,
    kind_stub: String,
    kubectl_stub: String,
) -> exitcode::ExitCode {
    let install_dir = match dir_parent {
        Some(x) => get_install_path(&x),
        None => {
            log(stderr, "Error: expected user homedir, got None\n");
            return exitcode::CANTCREAT;
        }
    };
    let arch = match get_arch(&raw_arch) {
        Some(x) => x,
        None => {
            log(
                stderr,
                &format!("Error: architecture `{}` is not supported\n", raw_arch),
            );
            return exitcode::OSERR;
        }
    };
    let os = match get_os(&raw_os) {
        Some(x) => x,
        None => {
            log(
                stderr,
                &format!("Error: OS `{}` is not supported\n", raw_os),
            );
            return exitcode::OSERR;
        }
    };
    match ensure_binaries_installed(install_dir.as_path(), arch, os, &kind_stub, &kubectl_stub)
        .await
    {
        Ok(_) => {}
        Err(e) => {
            log(
                stderr,
                &format!("Error: problem installing tools\nMessage: `{}`", e),
            );
            return exitcode::TEMPFAIL;
        }
    };

    let client = kube_client_factory();
    match args.cli_action {
        CliAction::Create {
            ref forward_postgres,
            sync,
        } => {
            let ref _fwd_postgres_tgt: String = helpers::forward_postgres_handle(&forward_postgres);
            if sync {
                log(stderr, "sync: true\n");
            }

            log(stderr, &format!("{}: create\n", konstants::NOT_IMPL));
            return exitcode::UNAVAILABLE;
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
            if overwrite_resources {
                log(stderr, "overwrite-resources: true\n");
            }
            log(stderr, &format!("id: {}\n", id_tgt));
            log(stderr, &format!("{}: start\n", konstants::NOT_IMPL));
            let fwd_postgres_tgt = helpers::forward_postgres_handle(&forward_postgres);
            if !(fwd_postgres_tgt.is_empty()) {
                let (namespace, cluster) = fwd_postgres_tgt.split_once("/").unwrap();
                let _pod = match helpers::get_pg_control_primary(client, cluster, namespace).await {
                    Ok(p) => log(stderr, &format!("{}\n", p)),
                    Err(e) => {
                        log(stderr, &format!("Error: {}\n", e));
                        return exitcode::TEMPFAIL;
                    }
                };
            }
            return exitcode::UNAVAILABLE;
        }
    };
}
