//! Developer tools for the CLI.
//! Primarily just shortcuts and helpers

use common::command::{RunHelper, ToCommand};
use futures::stream::FuturesUnordered;
use futures::TryStreamExt;
use serde::{Deserialize, Serialize};
use serde_with::{DeserializeFromStr, SerializeDisplay};
use std::fmt::Display;
use std::hash::Hash;
use std::str::FromStr;

use crate::config::Config;

use super::Result;
use tracing::{info, instrument, Instrument};

#[derive(Debug, Clone, Copy, Eq, SerializeDisplay, DeserializeFromStr)]
pub struct PortSpec {
    from: u16,
    to: u16,
}

impl Hash for PortSpec {
    fn hash<H: std::hash::Hasher>(&self, state: &mut H) {
        self.from.hash(state);
    }
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
impl ToCommand for ForwardSpec {
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

#[derive(Debug, clap::Parser)]
pub enum Commands {
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

fn default_namespace() -> String {
    "battery-core".to_string()
}

/// Port forwarding tools
#[derive(clap::Args, Debug, Serialize, Deserialize, Hash, PartialEq, Eq)]
pub struct ForwardSpec {
    /// Namespace containing destination pod
    #[clap(short, long, default_value = "battery-core", group("spec"))]
    #[serde(default = "default_namespace")]
    namespace: String,

    /// Destination thing (type/name) to forward to
    /// e.g. `deployment/battery-core-api` or `pods/pg-control-0`
    /// the special resource "all"
    resource: String,

    /// [LOCAL:]PORT pairs to forward
    #[clap(parse(try_from_str))]
    ports: Vec<PortSpec>,
}

impl Display for ForwardSpec {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let portstr = self
            .ports
            .iter()
            .map(ToString::to_string)
            .collect::<Vec<_>>()
            .join(", ");
        write!(f, "{}/{} <- {portstr}", self.namespace, self.resource,)
    }
}

/// Port forwarding tools
#[derive(Debug, clap::Parser, Serialize, Deserialize)]
pub struct ForwardArgs {
    #[clap(subcommand)]
    cmd: Option<ForwardCmd>,
}

#[derive(Debug, clap::Subcommand, Serialize, Deserialize)]
pub enum ForwardCmd {
    Add(ForwardSpec),
    List,
}

impl Commands {
    #[instrument(level = "debug")]
    pub async fn run(self) -> Result<()> {
        match self {
            Commands::Cluster(args) => {
                args.to_command().run().in_current_span().await?;
            }
            Commands::Forward(args) => {
                match args.cmd {
                    Some(ForwardCmd::List) => {
                        let mut out = Vec::new();
                        for spec in Config::load()?.port_forwards {
                            out.push(format!("{}", spec));
                        }
                        println!("{}", out.join("\n"));
                    }
                    Some(ForwardCmd::Add(spec)) => {
                        let mut cfg = Config::load().unwrap_or_default();
                        cfg.port_forwards.insert(spec);
                        cfg.save()?;
                    }
                    None => {
                        let config = Config::load()?;
                        // load all the forwards from the config then launch
                        // the worlds biggest future to run them all
                        let futs = config
                            .port_forwards
                            .into_iter()
                            .map(|f| f.to_command())
                            .map(|mut c| async move {
                                info!("Running {:?}", c);
                                c.run().in_current_span().await
                            })
                            .collect::<FuturesUnordered<_>>();

                        futs.try_collect::<Vec<_>>().in_current_span().await?;
                    }
                }
            }
        };
        Ok(())
    }
}
