#![deny(clippy::all)]
#![deny(clippy::pedantic)]
#![deny(clippy::nursery)]
#![allow(clippy::module_name_repetitions)]

use std::time::Duration;

use common::{
    cluster_spec::{
        ensure_crd, ensure_namespace, BatteryCluster, BatteryClusterSpec, DEFAULT_NAMESPACE,
    },
    error::Result,
    logging::try_init_logging,
    register::ClusterRegister,
};
use kube::{
    api::{Api, PostParams},
    client::Client,
};
use tokio::time::sleep;
use tracing::{debug, info};

const DEFAULT_CLUSTER_NAME: &str = "default-cluster";
const DEFAULT_ACCOUNT_NAME: &str = "test-account";
const DEFAULT_REG_SERVER: &str = "http://localhost:4000";

#[tokio::main]
async fn main() -> Result<()> {
    try_init_logging()?;
    // Connect to kubernetes
    debug!("Connecting to kubernetes.");
    let client = Client::try_default().await?;
    info!("Creating the namespace");
    ensure_namespace(client.clone()).await?;
    sleep(Duration::from_millis(500)).await;
    info!("Installing the CRD");
    ensure_crd(client.clone()).await?;

    info!("Registering the new cluster.");
    let reg_client = ClusterRegister::new(DEFAULT_REG_SERVER.to_string());
    let registration = reg_client.register().await?;

    // Hack alert. It seems like there's some delay between registering a crd and
    // being able to use it. so sleep for a while. This should be better handled
    // with retries.... Lame.
    info!("CRD present creating cluster");
    sleep(Duration::from_millis(500)).await;
    let clusters: Api<BatteryCluster> = Api::namespaced(client, DEFAULT_NAMESPACE);
    let new_cluster = BatteryCluster::new(
        DEFAULT_CLUSTER_NAME,
        BatteryClusterSpec {
            account: DEFAULT_ACCOUNT_NAME.to_string(),
            registered_cluster_id: registration.id.unwrap_or_default(),
        },
    );
    info!(new_cluster=?new_cluster);
    let pp = PostParams::default();
    clusters.create(&pp, &new_cluster).await?;
    info!("Install completed. Exiting.");
    Ok(())
}
