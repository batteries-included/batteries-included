#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

//! CLI for Batteries Included

use clap::Parser;
use common::error::Result;
use common::logging::try_init_logging;

mod bootstrap;
mod mount;
mod print_yaml;

/// Entry point to all things command-line
#[derive(clap::Parser)]
#[clap(name = "bi-cli", author)]
pub enum Cli {
    /// Bootstrap a new cluster
    Bootstrap,
    /// Print the shared yaml for bootstrap and control servers
    PrintYaml,
    /// Mount kubernetes
    Mount,
}

#[tokio::main]
async fn main() -> Result<()> {
    try_init_logging()?;
    let app = Cli::parse();

    match app {
        Cli::Bootstrap => bootstrap::run().await,
        Cli::PrintYaml => print_yaml::run(),
        Cli::Mount => mount::run(),
    }
}
