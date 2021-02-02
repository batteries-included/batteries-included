#![allow(clippy::default_trait_access)]
#![allow(clippy::field_reassign_with_default)]

use k8s_openapi::{
    api::core::v1::Namespace,
    apiextensions_apiserver::pkg::apis::apiextensions::v1::CustomResourceDefinition,
};
use kube::{
    api::{Api, ObjectMeta, Patch, PatchParams},
    client::Client,
    CustomResource,
};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use serde_json::json;
use tracing::debug;

use crate::error::Result;

pub const DEFAULT_CRD_NAME: &str = "batteryclusters.batteriesincluded.company";
pub const DEFAULT_NAMESPACE: &str = "battery";

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone)]
pub enum ClusterState {
    Unregistered,
    AwaitingAdoption,
    Running,
}

impl Default for ClusterState {
    fn default() -> Self {
        Self::Unregistered
    }
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
pub struct BatteryClusterStatus {
    pub current_state: ClusterState,
    pub registered_cluster_id: Option<String>,
}

#[derive(CustomResource, Serialize, Deserialize, JsonSchema, Default, Debug, Clone)]
#[kube(
    kind = "BatteryCluster",
    group = "batteriesincluded.company",
    shortname = "bc",
    version = "v1",
    status = "BatteryClusterStatus",
    namespaced
)]
pub struct BatteryClusterSpec {
    pub account: String,
}

pub async fn is_crd_installed(client: Client) -> bool {
    let crds: Api<CustomResourceDefinition> = Api::all(client);
    debug!("Trying to get the crd. If it's there we'll continue on");
    crds.get(DEFAULT_CRD_NAME).await.is_ok()
}

pub async fn is_namespace_installed(client: Client) -> bool {
    let ns: Api<Namespace> = Api::all(client);
    ns.get(DEFAULT_NAMESPACE).await.is_ok()
}

pub async fn ensure_namespace(client: Client) -> Result<()> {
    if is_namespace_installed(client.clone()).await {
        Ok(())
    } else {
        let crds: Api<Namespace> = Api::all(client);
        let params = PatchParams::apply("battery_operator").force();
        let new_ns = Namespace {
            metadata: ObjectMeta {
                name: Some(DEFAULT_NAMESPACE.to_string()),
                ..ObjectMeta::default()
            },
            ..Namespace::default()
        };
        let patch = Patch::Apply(json!(&new_ns));
        Ok(crds
            .patch(DEFAULT_NAMESPACE, &params, &patch)
            .await
            .map(|created_ns| {
                debug!(created =?created_ns);
            })?)
    }
}

pub async fn ensure_crd(client: Client) -> Result<()> {
    if is_crd_installed(client.clone()).await {
        Ok(())
    } else {
        let crds: Api<CustomResourceDefinition> = Api::all(client);
        let params = PatchParams::apply("battery_operator").force();
        debug!("Installing CRD.");
        let patch = Patch::Apply(serde_json::json!(&BatteryCluster::crd()));
        Ok(crds
            .patch(DEFAULT_CRD_NAME, &params, &patch)
            .await
            .map(|_| {
                debug!("Successfully installed CRD.");
            })?)
    }
}
