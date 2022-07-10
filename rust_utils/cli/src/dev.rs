//! Developer tools for the CLI.
//! Primarily just shortcuts and helpers

use std::process::{Command, ExitStatus};

pub type Result<T, E = anyhow::Error> = std::result::Result<T, E>;

#[derive(Debug, clap::Parser)]
pub enum DevCommands {
    /// Create the development cluster with all the default args:
    ///
    /// - no traefik, 3 servers, and whatever k3d has set up
    Cluster { name: Option<String> },
}

pub fn k3d_create_cluster(name: Option<&str>) -> Result<ExitStatus> {
    let arg_string = "cluster create \
                            -v /dev/mapper:/dev/mapper \
                            --k3s-arg --disable=traefik@server:* \
                            --registry-create battery-registry \
                            --wait \
                            -s 3";
    let mut args = arg_string.split_whitespace().collect::<Vec<_>>();
    if let Some(name) = name {
        args.push(name);
    }

    let mut cmd = Command::new("k3d");
    cmd.args(&args);

    let mut child = cmd.spawn()?;
    Ok(child.wait()?)
}

impl DevCommands {
    pub fn run(&self) -> Result<()> {
        match self {
            DevCommands::Cluster { name } => {
                let e = k3d_create_cluster(name.as_deref())?;
                if e.success() {
                    Ok(())
                } else {
                    Err(anyhow::anyhow!("k3d cluster create failed"))
                }
            }
        }
    }
}
