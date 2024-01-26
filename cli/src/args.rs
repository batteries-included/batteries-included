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
    pub current_dir: PathBuf,
    pub arch: String,
    pub os: String,
    pub temp_dir: PathBuf,
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
        #[clap(long, action = clap::ArgAction::Set, default_value_t = false,)]
        start_podman: bool,

        #[clap(long, default_value = "https://www.batteriesincl.com/specs/dev.json")]
        installation_url: Url,

        #[clap(long, default_value_t = false)]
        overwrite_resources: bool,
        #[clap(long, action = clap::ArgAction::Set, default_value_t = true)]
        forward_postgres: bool,
        #[clap(
            long,
            value_delimiter = ',',
            value_name = "NAMESPACE.POD:HOST_PORT:POD_PORT"
        )]
        forward_pods: Vec<String>,
        // The root dirctory of `platform_umbrella`
        #[clap(long)]
        platform_dir: Option<PathBuf>,
        // The root directory of `static`
        #[clap(long)]
        static_dir: Option<PathBuf>,

        // The install path inside the static directory
        #[clap(long, default_value = "public/specs/dev.json")]
        spec_path: Option<PathBuf>,
    },
    Uninstall,
    Stop {
        /// optional, positional customer id
        id: Option<String>,
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
    use std::path::PathBuf;

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
                platform_dir: None,
                static_dir: None,
                spec_path: Some(PathBuf::from("public/specs/dev.json")),
                forward_postgres: true,
                overwrite_resources: false,
                forward_pods: vec![],
                start_podman: false
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
                static_dir: None,
                spec_path: Some(PathBuf::from("public/specs/dev.json")),
                platform_dir: None,
                overwrite_resources: false,
                forward_pods: vec![],
                start_podman: false
            }
        )
    }

    #[tokio::test]
    async fn test_parse_dev_with_path_args() {
        let args = CliArgs::parse_from([
            "bcli",
            "dev",
            "--forward-postgres=false",
            "--static-dir=static",
            "--platform-dir=platform_umbrella",
        ]);
        assert_eq!(
            args.action,
            CliAction::Dev {
                installation_url: url::Url::parse("https://www.batteriesincl.com/specs/dev.json")
                    .expect("Parsable default"),
                forward_postgres: false,
                static_dir: Some(PathBuf::from("static")),
                spec_path: Some(PathBuf::from("public/specs/dev.json")),
                platform_dir: Some(PathBuf::from("platform_umbrella")),
                overwrite_resources: false,
                forward_pods: vec![],
                start_podman: false
            }
        )
    }

    #[tokio::test]
    async fn test_parse_dev_with_few_path_args() {
        let args = CliArgs::parse_from([
            "bcli",
            "dev",
            "--static-dir=static",
            "--spec-path=public/specs/dev_cluster.json",
            "--platform-dir=platform_umbrella",
        ]);
        assert_eq!(
            args.action,
            CliAction::Dev {
                installation_url: url::Url::parse("https://www.batteriesincl.com/specs/dev.json")
                    .expect("Parsable default"),
                forward_postgres: true,
                static_dir: Some(PathBuf::from("static")),
                spec_path: Some(PathBuf::from("public/specs/dev_cluster.json")),
                platform_dir: Some(PathBuf::from("platform_umbrella")),
                overwrite_resources: false,
                forward_pods: vec![],
                start_podman: false
            }
        )
    }

    #[tokio::test]
    async fn test_parse_stop() {
        let args = CliArgs::parse_from(["bcli", "stop"]);
        assert_eq!(args.action, CliAction::Stop { id: None })
    }
}
