#![deny(clippy::all)]
#![deny(clippy::nursery)]

use actix::{Actor, System};

use kube::client::Client;
use tracing::{debug, info};

use clap::{App, Arg};
use common::logging::try_init_logging;
use controller_core::{actors::root::RootClusterActor, cs_client::ControlServerClient};

#[cfg(not(target_env = "msvc"))]
use jemallocator::Jemalloc;

#[cfg(not(target_env = "msvc"))]
#[global_allocator]
static GLOBAL: Jemalloc = Jemalloc;

#[tokio::main]
async fn main() {
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

    try_init_logging().unwrap();

    let server_url = matches
        .value_of("server_url")
        .unwrap_or("http://localhost:4000")
        .to_string();

    info!("Server url = {server_url} ", server_url = server_url);

    let mut sys = System::new("root_system");

    let _addr = sys.block_on(async move {
        // Connect to kubernetes
        let kube_client = Client::try_default().await.unwrap();

        debug!("kube client created. Creating the control server client");
        let cs_client = ControlServerClient::new(server_url.to_string());

        RootClusterActor::new(kube_client, cs_client).start()
    });

    sys.run().unwrap();
}
