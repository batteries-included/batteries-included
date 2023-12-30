use eyre::{ContextCompat, Result};
use futures::{StreamExt, TryStreamExt};
use k8s_openapi::api::core::v1::Pod;
use kube_client::{
    api::{ListParams, WatchParams},
    Api, Client,
};
use kube_runtime::wait::{await_condition, conditions::is_pod_running};
use tracing::{debug, info};

const LABEL_SELECTOR: &str = "cnpg.io/cluster=pg-controlserver,role=primary";
const INITIAL_PODNAME: &str = "pg-controlserver-1";
const DEFAULT_RESOURCE_VERSION: &str = "0";

pub async fn wait_healthy_pg(kube_client: Client, namespace: &str) -> Result<()> {
    info!("Waiting for the first postgres pod to be running");
    let pods: Api<Pod> = Api::namespaced(kube_client, namespace);
    // Wait for the first control postgres
    let establish = await_condition(pods, INITIAL_PODNAME, is_pod_running());
    let _ = tokio::time::timeout(std::time::Duration::from_secs(900), establish).await?;
    info!("First postgres pod is running");
    Ok(())
}

/// Gets the name of the primary Postgres pod by querying for pods with the
/// controlserver-primary label selector. If no pod is initially found, watches
/// for a Added or Modified event matching the selector.
pub async fn master_name(pods: Api<Pod>) -> Result<String> {
    debug!("Getting master name from label selector");
    let list_params = ListParams::default().labels(LABEL_SELECTOR);
    let list = pods.list(&list_params).await?;
    if list.items.is_empty() {
        // Watches for Added or Modified pod events matching the label selector.
        // Uses the resourceVersion from the initial list API response to start watching from.
        // Boxes the stream to make it able to be held across await points.
        let rv = list
            .metadata
            .resource_version
            .unwrap_or_else(|| DEFAULT_RESOURCE_VERSION.to_string());
        let watch_params = WatchParams::default()
            .labels(LABEL_SELECTOR)
            .disable_bookmarks();
        let mut stream = pods.watch(&watch_params, &rv).await?.boxed();

        // After watch fires for the first time we expect the first event to
        // contain the pod name.
        let res = stream
            .try_next()
            .await?
            .and_then(|event| match event {
                kube_client::core::WatchEvent::Added(pod) => pod.metadata.name,
                kube_client::core::WatchEvent::Modified(pod) => pod.metadata.name,
                _event => None,
            })
            .context("Expected a pod name after timeout of 290 seconds")?;
        Ok(res)
    } else {
        // Gets the name of the first pod in the list.
        // Returns an error if there are no pods or more than one pod.
        let pod_name = list
            .into_iter()
            .next()
            .and_then(|p| p.metadata.name)
            .context("We should have only one name by now")?;

        Ok(pod_name)
    }
}
