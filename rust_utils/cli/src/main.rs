#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]
#![allow(clippy::type_repetition_in_bounds)]

//! CLI for Batteries Included

use clap::Parser;
use common::logging::try_init_logging;

mod bootstrap;
mod dev;

/// Entry point to all things command-line
#[derive(Debug, clap::Parser)]
pub enum Cli {
    /// Dump the contents of the embeddedb bootstrap yamls into the default kubernetes cluster
    Bootstrap,
    /// Developer tools
    #[clap(subcommand)]
    Dev(dev::DevCommands),
}

#[derive(Debug, clap::Parser)]
#[clap(name = "bi-cli", author, rename_all = "kebab-case")]
pub struct CliArgs {
    #[clap(short)]
    pub log_level: tracing::Level,
    #[clap(subcommand)]
    pub command: Cli,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    try_init_logging()?;
    let app = Cli::parse();

    match app {
        Cli::Bootstrap => bootstrap::run().await,
        Cli::Dev(dev_args) => Ok(dev_args.run()?),
    }
}
