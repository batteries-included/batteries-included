use std::{
    io::{BufRead, Write},
    path::PathBuf,
};

use helpers::{get_arch, get_install_path};

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

pub mod konstants {
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
    use std::path::{Path, PathBuf};

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
            konstants::AMD64 => return Some(konstants::AMD64),
            konstants::X86_64 => Some(konstants::AMD64),
            konstants::AARCH64 => Some(konstants::ARM64),
            konstants::ARM64 => Some(konstants::ARM64),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use clap::Parser;
    use hyper::Body;
    use k8s_openapi::http::{Request, Response};

    use crate::konstants;
    use crate::program_main;
    use crate::Args;

    use tower_test::mock;

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
    async fn test_blank() {
        let mut err = Vec::new();
        let mut out = Vec::new();
        let input = "".as_bytes();
        let tmp = tempdir::TempDir::new("test_blank").unwrap();
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
) -> exitcode::ExitCode {
    // TODO: wire this up for downloading kubectl and kind
    let _install_dir = match dir_parent {
        Some(x) => get_install_path(&x),
        None => {
            log(stderr, "Error: expected user homedir, got None\n");
            return exitcode::CANTCREAT;
        }
    };
    // TODO: wire this into downloading kubectl and kind
    let _arch = match get_arch(&raw_arch) {
        Some(x) => x,
        None => {
            log(
                stderr,
                &format!("Error: architecture `{}` is not supported\n", raw_arch),
            );
            return exitcode::OSERR;
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
