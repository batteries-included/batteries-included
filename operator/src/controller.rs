#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

mod bat_logging;
mod cluster_spec;
mod cs_client;
mod error;
mod manager;

use bat_logging::try_init_logging;
use clap::{App, Arg};
use cs_client::ControlServerClient;
#[cfg(not(target_env = "msvc"))]
use jemallocator::Jemalloc;
use kube::client::Client;
use tracing::{debug, info};

use crate::{error::BatteryError, manager::Manager};

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

    let server_url = matches
        .value_of("server_url")
        .unwrap_or("http://localhost:4000");

    info!("Server url = {server_url} ", server_url = server_url);

    // Connect to kubernetes
    let kube_client = Client::try_default().await?;

    debug!("kube client created. Creating the control server client");
    let ctrl_client = ControlServerClient::new(server_url.to_string());

    let manager = Manager::new(kube_client, ctrl_client).await?;

    manager.drainer.await;

    // Let the world know. Bye.
    info!("Manager drained. Shutting down.");
    Ok(())
}
