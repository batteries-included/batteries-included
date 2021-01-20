#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

mod bat_logging;
mod cluster_spec;
mod error;
mod manager;

use bat_logging::try_init_logging;
use kube::client::Client;

use clap::{App, Arg};
use tracing::{debug, info};

use crate::{error::BatteryError, manager::Manager};

#[cfg(not(target_env = "msvc"))]
use jemallocator::Jemalloc;

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: Jemalloc = Jemalloc;

#[tokio::main]
async fn main() -> Result<(), BatteryError> {
    let matches = App::new("Batteries Included")
        .author("Elliott Clark <elliott.neil.clark@gmail.com>")
        .arg(
            Arg::with_name("server_url")
                .long("server_url")
                .short("s")
                .takes_value(true)
                .value_name("URL")
                .help("The base url for communication with backend server"),
        )
        .get_matches();

    try_init_logging()?;

    let server_url = match matches.value_of("server_url") {
        Some(si) => si,
        None => "http://localhost:4000",
    };

    info!("Server url = {server_url} ", server_url = server_url);

    // Connect to kubernetes
    let client = Client::try_default().await?;

    debug!("kube client created starting manager.");
    let manager = Manager::new(client, server_url.to_string()).await?;

    tokio::select! {
        _ = manager.drainer => info!("Manager drained"),
    }
    Ok(())
}
