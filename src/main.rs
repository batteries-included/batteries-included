#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

mod cluster_spec;
mod error;
mod manager;

use kube::client::Client;

use tracing::info;

use crate::error::BatteryError;
use crate::manager::Manager;

#[tokio::main]
async fn main() -> Result<(), BatteryError> {
    // Connect to kubernetes
    let client = Client::try_default().await?;
    // Create a new manager and the future that will wait on all reconcilers.
    let manager = Manager::new(client).await?;

    tokio::select! {
        _ = manager.drainer => info!("Manager drained"),
    }
    Ok(())
}
