mod helpers;

use std::{
    io::{BufRead, Write},
    path::PathBuf,
};

#[derive(clap::Parser)]
pub struct CliArgs {
    #[command(subcommand)]
    cli_action: CliAction,
}

// TODO: add setters so that we can reduce boilerplate in tests
// with a factory method for constructing a base test ProgramArgs struct
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
    // subcommand `dev` is hidden from help output
    #[clap(hide = true)]
    Dev {
        #[clap(long)]
        forward_postgres: Option<Option<String>>,
        #[clap(long, default_value_t = true)]
        create_cluster: bool,
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
    pub(crate) struct KindClusterError(String);

    impl fmt::Display for KindClusterError {
        fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
            write!(f, "Error creating or getting kind cluster: {}", self.0)
        }
    }

    impl Error for KindClusterError {}

    impl KindClusterError {
        pub fn new(output: String) -> KindClusterError {
            Self(output)
        }
    }
}

pub mod prod {
    pub const URL_STUB_KIND: &str =
        "https://github.com/kubernetes-sigs/kind/releases/download/v0.17.0";
    pub const URL_STUB_KUBECTL: &str = "https://dl.k8s.io/release/v1.25.4/bin";
}

mod statik {
    pub(crate) const DEV_JSON: &str = include_str!("../../static/static/installations/dev.json");
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
    write!(stderr, "{}", msg).unwrap();
    stderr.flush().unwrap();
}

pub async fn program_main<'a>(args: &mut ProgramArgs<'_>) -> exitcode::ExitCode {
    let install_dir = match &args.dir_parent {
        Some(x) => helpers::get_install_path(x),
        None => {
            log(args.stderr, "Error: expected user homedir, got None\n");
            return exitcode::CANTCREAT;
        }
    };
    let arch = match helpers::get_arch(&args.raw_arch) {
        Some(x) => x,
        None => {
            log(
                args.stderr,
                &format!("Error: architecture `{}` is not supported\n", args.raw_arch),
            );
            return exitcode::OSERR;
        }
    };
    let os = match helpers::get_os(&args.raw_os) {
        Some(x) => x,
        None => {
            log(
                args.stderr,
                &format!("Error: OS `{}` is not supported\n", args.raw_os),
            );
            return exitcode::OSERR;
        }
    };
    match helpers::ensure_binaries_installed(
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

    let rc = match &args.cli_args.cli_action {
        // INCOMPLETE
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
        // COMPLETE
        CliAction::Dev {
            ref forward_postgres,
            create_cluster,
        } => {
            match helpers::ensure_binaries_installed(
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

            if *create_cluster {
                // start kind cluster
                let mut kind_path = PathBuf::from(&install_dir);
                kind_path.push("kind");

                // TODO: change hardcoded cluster name
                match helpers::kind_cluster(
                    &kind_path,
                    "battery",
                    args.dir_parent.as_ref().unwrap(),
                ) {
                    Err(e) => {
                        log(args.stderr, &e.to_string());
                        return exitcode::SOFTWARE;
                    }
                    Ok(_) => ..,
                };
            }

            // load custom resources to cluster
            let mut kubectl_path = PathBuf::from(&install_dir);
            kubectl_path.push("kubectl");
            let _res = helpers::apply_resources(&kubectl_path, statik::DEV_JSON);

            // port-forward postgres
            let fwd_postgres_tgt = helpers::forward_postgres_handle(forward_postgres);
            if !(fwd_postgres_tgt.is_empty()) {
                let (namespace, cluster) = fwd_postgres_tgt.split_once('/').unwrap();
                match helpers::forward_postgres(
                    &args.kube_client_factory,
                    kubectl_path,
                    cluster,
                    namespace,
                    5432,
                )
                .await
                {
                    Ok(_) => {
                        log(args.stderr, "Received signal, shutting down...\n");
                    }
                    Err(e) => {
                        log(args.stderr, &format!("Error: {e}\n"));
                        return exitcode::TEMPFAIL;
                    }
                };
            }
            exitcode::OK
        }

        // INCOMPLETE
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
            // TODO: refactor this because it's repeated in a few places
            if !(fwd_postgres_tgt.is_empty()) {
                let (namespace, cluster) = fwd_postgres_tgt.split_once('/').unwrap();
                match helpers::get_pg_control_primary(&args.kube_client_factory, cluster, namespace)
                    .await
                {
                    Ok(p) => log(args.stderr, &format!("{p}\n")),
                    Err(e) => {
                        log(args.stderr, &format!("Error: {e}\n"));
                        return exitcode::TEMPFAIL;
                    }
                };
            }
            exitcode::UNAVAILABLE
        }
    };
    rc
}
