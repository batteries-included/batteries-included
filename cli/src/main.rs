use clap::Parser;
use log::{error, trace};

static NOT_IMPL: &str = "Not yet implemented";
static DEFAULT_POSTGRES_FWD_TGT: &str = "battery-base/pg-control";

#[derive(clap::Parser)]
struct Args {
    #[command(subcommand)]
    cli_action: CliAction,
}

#[derive(clap::Subcommand)]
enum CliAction {
    Create {
        #[clap(long)]
        forward_postgres: Option<Option<String>>,
        #[clap(long, default_value_t = false)]
        sync: bool
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

#[cfg(test)]
mod tests {
    use assert_cmd::Command;
    use predicates::prelude::*;
    use predicates::str::contains;
    use crate::DEFAULT_POSTGRES_FWD_TGT;
    static HELP_STR: &str = r#"Usage: cli <COMMAND>

Commands:
  create  
  start   
  help    Print this message or the help of the given subcommand(s)

Options:
  -h, --help  Print help
"#;
    static IMPL_ERR_STR: &str = "[ERROR cli] Not yet implemented";

    #[test]
    fn test_blank() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.assert()
            .failure()
            .stderr(predicate::eq(HELP_STR));
    }

    #[test]
    fn test_help() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("help")
            .assert()
            .success()
            .stdout(predicate::eq(HELP_STR));
    }

    #[test]
    fn test_create_no_flags() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("create")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(format!("{}: create", IMPL_ERR_STR)))
            .stdout(predicate::eq(""));
    }

    #[test]
    fn test_create_foward_postgres_no_target_no_sync() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("create")
            .arg("--forward-postgres")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(format!("{}: create", IMPL_ERR_STR)))
            .stderr(contains(format!("forward-postgres: {}", DEFAULT_POSTGRES_FWD_TGT)))
            .stdout(predicate::eq(""));
    }

    #[test]
    fn test_create_foward_postgres_with_target_no_sync() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("create")
            .arg("--forward-postgres")
            .arg("foo/bar")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(IMPL_ERR_STR))
            .stderr(contains("forward-postgres: foo/bar"))
            .stdout(predicate::eq(""));
    }

    #[test]
    fn test_create_foward_postgres_with_target_with_sync() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("create")
            .arg("--forward-postgres")
            .arg("foo/bar")
            .arg("--sync")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(IMPL_ERR_STR))
            .stderr(contains("forward-postgres: foo/bar"))
            .stderr(contains("sync: true"))
            .stdout(predicate::eq(""));
    }

    #[test]
    fn test_start_no_flags() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("start")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(IMPL_ERR_STR))
            .stderr(contains("id: demo"))
            .stdout(predicate::eq(""));
    }

    #[test]
    fn test_start_forward_postgres_no_target() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("start")
            .arg("--forward-postgres")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(IMPL_ERR_STR))
            .stderr(contains("id: demo"))
            .stderr(contains(format!("forward-postgres: {}", DEFAULT_POSTGRES_FWD_TGT)))
            .stdout(predicate::eq(""));
    }

    #[test]
    fn test_start_forward_postgres_with_target() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("start")
            .arg("--forward-postgres")
            .arg("baz/qux")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(IMPL_ERR_STR))
            .stderr(contains("id: demo"))
            .stderr(contains("forward-postgres: baz/qux"))
            .stdout(predicate::eq(""));
    }

    #[test]
    fn test_start_forward_postgres_with_target_with_overwrite_resources() {
        let mut cmd = Command::cargo_bin(env!("CARGO_PKG_NAME")).unwrap();
        cmd.arg("start")
            .arg("--forward-postgres")
            .arg("baz/qux")
            .arg("--overwrite-resources")
            .env("RUST_LOG", "trace")
            .assert()
            .failure()
            .stderr(contains(format!("{}: start", IMPL_ERR_STR)))
            .stderr(contains("id: demo"))
            .stderr(contains("forward-postgres: baz/qux"))
            .stderr(contains("overwrite-resources: true"))
            .stdout(predicate::eq(""));
    }
}

fn forward_postgres_handle(fwd_postgres_opt: Option<Option<String>>) -> String {
    let fwd_postgres = match fwd_postgres_opt {
        None => {
            "".to_string()
        },
        Some(None) => {
            DEFAULT_POSTGRES_FWD_TGT.to_string()
        },
        Some(tgt_opt) => {
            tgt_opt.unwrap().trim().to_string()
        },
    };
    if !fwd_postgres.is_empty() {
        trace!("forward-postgres: {}", fwd_postgres);
    }
    fwd_postgres
}

fn main() {
    env_logger::builder()
    .format_timestamp(None)
    .init();
    let args = Args::parse();
    match args.cli_action {
        CliAction::Create { forward_postgres, sync } => {
            let _fwd_postgres_tgt = forward_postgres_handle(forward_postgres);
            if sync {
                trace!("sync: true");
            }
            error!("{}: create", NOT_IMPL);
            std::process::exit(exitcode::UNAVAILABLE);
        },
        CliAction::Start { forward_postgres, id, overwrite_resources} => {
            let id_tgt = match id {
                None => {
                    "demo".to_string()
                },
                Some(tgt) => {
                    tgt
                },
            };
            let _fwd_postgres_tgt = forward_postgres_handle(forward_postgres);
            if overwrite_resources {
                trace!("overwrite-resources: true")
            }
            trace!("id: {}", id_tgt);
            error!("{}: start", NOT_IMPL);
            std::process::exit(exitcode::UNAVAILABLE);
        },
    };
}


