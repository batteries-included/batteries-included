use crate::{error::Result, labels::default_labels};
use k8s_openapi::api::core::v1::Namespace;
use kube::{
    api::{ObjectMeta, Patch, PatchParams},
    Api, Client,
};
use serde_json::json;
use tracing::debug;

pub const DEFAULT_NAMESPACE: &str = "battery-core";

pub fn default_namespace() -> Namespace {
    Namespace {
        metadata: ObjectMeta {
            name: Some(DEFAULT_NAMESPACE.to_string()),
            labels: Some(default_labels("batteries-included")),
            ..ObjectMeta::default()
        },
        ..Namespace::default()
    }
}

pub async fn is_namespace_installed(client: Client) -> bool {
    let ns: Api<Namespace> = Api::all(client);
    debug!("Trying to get the namespace");
    let res = ns.get(DEFAULT_NAMESPACE).await;
    debug!("Got a result.");
    res.is_ok()
}

pub async fn ensure_namespace(client: Client) -> Result<()> {
    if is_namespace_installed(client.clone()).await {
        Ok(())
    } else {
        let crds: Api<Namespace> = Api::all(client);
        let params = PatchParams::apply("battery_operator").force();
        let patch = Patch::Apply(json!(&default_namespace()));
        Ok(crds
            .patch(DEFAULT_NAMESPACE, &params, &patch)
            .await
            .map(|created_ns| {
                debug!(created =?created_ns);
            })?)
    }
}
