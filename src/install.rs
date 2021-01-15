#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

mod cluster_spec;
mod error;

use kube::{
    api::{Api, PostParams},
    client::Client,
};
use tracing::{debug, info};

use crate::{
    cluster_spec::{install_crd, BatteryCluster, BatteryClusterSpec},
    error::BatteryError,
};

#[tokio::main]
async fn main() -> Result<(), BatteryError> {
    tracing_subscriber::fmt::init();
    // Connect to kubernetes
    debug!("Connecting to kubernetes.");
    let client = Client::try_default().await?;
    info!("Installing the CRD");
    install_crd(client.clone()).await?;
    info!("CRD present creating default cluster");
    let clusters: Api<BatteryCluster> = Api::all(client);
    let new_cluster = BatteryCluster::new(
        "default-cluster",
        BatteryClusterSpec {
            account: "test-account".to_string(),
        },
    );
    let pp = PostParams::default();
    clusters.create(&pp, &new_cluster).await?;
    Ok(())
}
