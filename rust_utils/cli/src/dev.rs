//! Developer tools for the CLI.
//! Primarily just shortcuts and helpers

use common::command::{RunHelper, ToCommand};
use std::fmt::Display;
use std::process::ExitStatus;
use std::str::FromStr;
use tokio::process::Command;

use super::Result;
use tracing::{instrument, Instrument};

#[derive(Debug, Clone, Copy)]
pub struct PortSpec {
    from: u16,
    to: u16,
}

impl PartialEq for PortSpec {
    fn eq(&self, other: &Self) -> bool {
        // ports on the other side can clash, but local cant
        self.from == other.from
    }
}

impl Display for PortSpec {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}:{}", self.from, self.to)
    }
}

impl FromStr for PortSpec {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let parts = s
            .split(':')
            .filter_map(|s| s.parse::<u16>().ok())
            .collect::<Vec<_>>();
        match parts[..] {
            [from, to] => Ok(Self { from, to }),
            [to] => Ok(Self { from: to, to }),
            _ => Err("Expected `from:to` or `to`".to_string()),
        }
    }
}

//fn make_args(ns: &str, dst: &str, p: &[PortSpec]) -> Vec<String> {
impl ToCommand for ForwardArgs {
    fn cmd_name(&self) -> &str {
        "kubectl"
    }

    #[instrument(level = "debug")]
    fn to_args(&self) -> Vec<String> {
        let mut out: Vec<String> =
            IntoIterator::into_iter(["port-forward", "-n", &self.namespace, &self.resource])
                .map(ToString::to_string)
                .collect();
        out.extend(self.ports.iter().map(ToString::to_string));
        out
    }
}

impl ToCommand for ClusterArgs {
    fn cmd_name(&self) -> &str {
        "k3d"
    }

    #[instrument(level = "debug")]
    fn to_args(&self) -> Vec<String> {
        let mut args: Vec<String> = [
            "cluster",
            "create",
            "-v",
            "/dev/mapper:/dev/mapper",
            "--k3s-arg",
            "--disable=traefik@server:*",
            "--registry-create",
            "battery-registry",
            "--wait",
            "-s",
            "3",
        ]
        .iter()
        .map(ToString::to_string)
        .collect();

        if let Some(name) = &self.name {
            args.push(name.to_string());
        }
        args
    }
}

#[instrument]
async fn forward_ports(args: &ForwardArgs) -> Result<ExitStatus> {
    let args = args.to_args();
    Command::new("kubectl").args(&args).run().await
}

#[derive(Debug, clap::Parser)]
pub enum DevCommands {
    Cluster(ClusterArgs),
    Forward(ForwardArgs),
}

/// Create the development cluster with all the default args:
///
/// - no traefik, 3 servers, and whatever k3d has set up
#[derive(clap::Parser, Debug)]
pub struct ClusterArgs {
    name: Option<String>,
}

/// Port forwarding tools
#[derive(clap::Parser, Debug)]
pub struct ForwardArgs {
    /// Namespace of destination service (default: battery-core)
    #[clap(short, long, default_value = "battery-core")]
    namespace: String,

    /// Destination thing (type/name) to forward to
    resource: String,

    /// [LOCAL:]PORT pairs to forward
    #[clap(parse(try_from_str))]
    ports: Vec<PortSpec>,
}

impl DevCommands {
    #[instrument(level = "debug")]
    pub async fn run(&self) -> Result<()> {
        match self {
            DevCommands::Cluster(args) => args.to_command().run().in_current_span().await?,
            DevCommands::Forward(args) => args.to_command().run().in_current_span().await?,
        };
        Ok(())
    }
}
