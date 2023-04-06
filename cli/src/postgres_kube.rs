use eyre::{ContextCompat, Result};
use futures::{StreamExt, TryStreamExt};
use k8s_openapi::api::core::v1::Pod;
use kube_client::{api::ListParams, Api, Client};
use kube_runtime::wait::{await_condition, conditions::is_pod_running};
use tracing::info;

pub async fn wait_healthy_pg(kube_client: Client, namespace: &str) -> Result<()> {
    info!("Waiting for the first postgres pod to be running");
    let pods: Api<Pod> = Api::namespaced(kube_client, namespace);
    // Wait for the first control postgres
    let establish = await_condition(pods, "pg-control-0", is_pod_running());
    let _ = tokio::time::timeout(std::time::Duration::from_secs(900), establish).await?;
    Ok(())
}

pub async fn master_name(pods: Api<Pod>) -> Result<String> {
    let list_params = ListParams::default()
        .labels("spilo-role=master,cluster-name=pg-control")
        .disable_bookmarks()
        .timeout(290);
    let list = pods.list(&list_params).await?;
    if list.items.is_empty() {
        let rv = list
            .metadata
            .resource_version
            .unwrap_or_else(|| "0".to_string());
        let mut stream = pods.watch(&list_params, &rv).await?.boxed();
        let res = stream.try_next().await?.and_then(|event| match event {
            kube_client::core::WatchEvent::Added(pod) => pod.metadata.name,
            kube_client::core::WatchEvent::Modified(pod) => pod.metadata.name,
            _event => None,
        });

        Ok(res.context("Expected a pod name after timeout of 290 seconds")?)
    } else {
        let pod_name = list.into_iter().next().and_then(|p| p.metadata.name);
        Ok(pod_name.context("We should have only one name by now")?)
    }
}
