#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

use clap::{App, AppSettings};
use common::error::Result;
use common::logging::try_init_logging;
use tracing::debug;

mod bootstrap;
mod print_yaml;

#[tokio::main]
async fn main() -> Result<()> {
    try_init_logging()?;

    let matches = App::new("batteries-included")
        .version("1.0")
        .author("Elliott Clark <elliott@batteriesincl.com>")
        .about("Control the world/cluster")
        .setting(AppSettings::ColoredHelp)
        .setting(AppSettings::SubcommandRequiredElseHelp)
        .subcommand(App::new("bootstrap").about("Bootstrap a new cluster"))
        .subcommand(
            App::new("print_yaml").about("Print the shared yaml for bootstrap and control server"),
        )
        .get_matches();

    match matches.subcommand() {
        ("bootstrap", _) => bootstrap::run().await?,
        ("print_yaml", _) => print_yaml::run()?,
        _ => debug!("Unknown command"),
    }

    Ok(())
}
