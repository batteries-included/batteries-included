#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

mod cluster_spec;
mod error;
mod manager;

use kube::client::Client;

use tracing::{debug, info};

use crate::{error::BatteryError, manager::Manager};

#[tokio::main]
async fn main() -> Result<(), BatteryError> {
    tracing_subscriber::fmt::init();
    // Connect to kubernetes
    let client = Client::try_default().await?;

    debug!("kube client created starting manager.");
    let manager = Manager::new(client).await?;

    tokio::select! {
        _ = manager.drainer => info!("Manager drained"),
    }
    Ok(())
}
