use std::path::PathBuf;
use url::Url;

#[derive(clap::Parser)]
pub struct CliArgs {
    #[command(subcommand)]
    pub action: CliAction,

    #[clap(flatten)]
    pub verbose: clap_verbosity_flag::Verbosity,
}
pub struct BaseArgs {
    pub kube_client_factory: Box<dyn Fn() -> kube_client::Client>,
    pub dir_parent: PathBuf,
    pub arch: String,
}

// TODO: add setters so that we can reduce boilerplate in tests
// with a factory method for constructing a base test ProgramArgs struct
pub struct ProgramArgs {
    pub cli_args: CliArgs,
    pub base_args: BaseArgs,
}

#[derive(clap::Subcommand, PartialEq, PartialOrd, Debug)]
pub enum CliAction {
    // subcommand `dev` is hidden from help output
    #[clap(hide = true)]
    Dev {
        #[clap(long, default_value = "https://www.batteriesincl.com/specs/dev.json")]
        installation_url: Url,
        #[clap(long, default_value_t = false)]
        overwrite_resources: bool,
        #[clap(long, action = clap::ArgAction::Set, default_value_t = true)]
        forward_postgres: bool,
    },
    Start {
        /// optional, positional customer id
        id: Option<String>,

        #[clap(long, default_value_t = false)]
        overwrite_resources: bool,
    },
}

#[cfg(test)]
mod tests {
    use super::{CliAction, CliArgs};
    use clap::Parser;

    #[tokio::test]
    async fn test_parse_start() {
        let args = CliArgs::parse_from(["bcli", "start"]);
        assert_eq!(
            args.action,
            CliAction::Start {
                id: None,
                overwrite_resources: false
            }
        )
    }

    #[tokio::test]
    async fn test_parse_dev() {
        let args = CliArgs::parse_from(["bcli", "dev"]);
        assert_eq!(
            args.action,
            CliAction::Dev {
                installation_url: url::Url::parse("https://www.batteriesincl.com/specs/dev.json")
                    .expect("Parsable default"),
                forward_postgres: true,
                overwrite_resources: false
            }
        )
    }

    #[tokio::test]
    async fn test_parse_dev_with_args() {
        let args = CliArgs::parse_from([
            "bcli",
            "dev",
            "--forward-postgres=false",
            "--installation-url=http://localhost:3000/specs/dev.json",
        ]);
        assert_eq!(
            args.action,
            CliAction::Dev {
                forward_postgres: false,
                installation_url: url::Url::parse("http://localhost:3000/specs/dev.json")
                    .expect("Parsable default"),
                overwrite_resources: false,
            }
        )
    }
}
