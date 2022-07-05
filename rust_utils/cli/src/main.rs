#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]
#![allow(clippy::type_repetition_in_bounds)]

//! CLI for Batteries Included

use clap::Parser;
use common::error::Result;
use common::logging::subscriber::{self, EnvFilter};
use tracing::{info_span, Instrument};

mod bootstrap;
mod print_yaml;

/// Entry point to all things command-line
#[derive(Debug, clap::Parser)]
pub enum Cli {
    Bootstrap(bootstrap::BootstrapArgs),
    /// Print the shared yaml for bootstrap and control servers
    PrintYaml,
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
async fn main() -> Result<()> {
    let app = CliArgs::parse();

    let filter = EnvFilter::try_from_default_env()
        .or_else(|_| EnvFilter::try_new("cli=info"))
        .unwrap();

    subscriber::fmt()
        .with_env_filter(filter)
        .with_max_level(app.log_level)
        .try_init()
        .unwrap();

    match app.command {
        Cli::Bootstrap(args) => args.run().instrument(info_span!("bootstrap")).await,
        Cli::PrintYaml => print_yaml::run(),
    }
}
