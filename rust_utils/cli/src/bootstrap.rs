use std::time::Duration;

use common::{
    cluster_spec::ensure_crd,
    cluster_spec::ensure_default_cluster,
    error::Result,
    namespace::ensure_namespace,
    permissions::{ensure_admin, ensure_service_account},
};
use kube::client::Client;
use tokio::time::sleep;
use tracing::{debug, info};

pub async fn run() -> Result<()> {
    // Connect to kubernetes
    debug!("Connecting to kubernetes.");
    let client = Client::try_default().await?;
    info!("Creating the namespace");
    ensure_namespace(client.clone()).await?;
    sleep(Duration::from_millis(500)).await;
    info!("Creating the ServiceAccount");
    ensure_service_account(client.clone()).await?;
    info!("Attaching ClusterRoleBinding");
    ensure_admin(client.clone()).await?;
    info!("Installing the CRD");
    ensure_crd(client.clone()).await?;

    // Hack alert. It seems like there's some delay between registering a crd and
    // being able to use it. so sleep for a while. This should be better handled
    // with retries.... Lame.
    sleep(Duration::from_millis(2000)).await;

    info!("CRD present creating cluster");
    ensure_default_cluster(client).await?;
    Ok(())
}
