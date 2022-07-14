#![deny(clippy::pedantic)]

//! CLI for Batteries Included

pub use color_eyre::Result;

use clap::Parser;
use common::logging::subscriber::{self, prelude::*, EnvFilter};
use tracing::{info_span, Instrument};
use tracing_error::ErrorLayer;

mod bootstrap;
mod config;
mod dev;

/// Entry point to all things command-line
#[derive(Debug, clap::Parser)]
pub enum Cli {
    /// Apply the bootstrap YAMLs to the default kubernetes cluster
    Bootstrap,
    /// Developer tools
    #[clap(flatten)]
    Dev(dev::Commands),
}

#[derive(Debug, clap::Parser)]
#[clap(name = "bi-cli", author, rename_all = "kebab-case")]
pub struct CliArgs {
    #[clap(subcommand)]
    pub command: Cli,
}

#[tokio::main]
async fn main() -> Result<()> {
    color_eyre::install()?;
    let app = CliArgs::parse();

    let filter = EnvFilter::try_from_default_env()
        .or_else(|_| EnvFilter::try_new("cli=info"))
        .unwrap();

    subscriber::fmt()
        .with_env_filter(filter)
        .finish()
        .with(ErrorLayer::default())
        .try_init()?;

    match app.command {
        Cli::Bootstrap => bootstrap::run().instrument(info_span!("bootstrap")).await?,
        Cli::Dev(dev) => dev.run().instrument(info_span!("dev")).await?,
    };
    Ok(())
}
