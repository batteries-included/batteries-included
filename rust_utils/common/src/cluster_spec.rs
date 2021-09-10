#![allow(clippy::default_trait_access)]
#![allow(clippy::field_reassign_with_default)]

use k8s_openapi::apiextensions_apiserver::pkg::apis::apiextensions::v1::CustomResourceDefinition;
use kube::{
    api::{Api, Patch, PatchParams},
    client::Client,
    CustomResource, CustomResourceExt,
};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use serde_json::json;
use tracing::debug;

use crate::error::Result;

pub const DEFAULT_CRD_NAME: &str = "batteryclusters.batteriesincl.com";

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone)]
pub enum ClusterState {
    AwaitingAdoption,
    Running,
}

impl Default for ClusterState {
    fn default() -> Self {
        Self::AwaitingAdoption
    }
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
pub struct BatteryClusterStatus {
    pub current_state: ClusterState,
}

#[derive(CustomResource, Serialize, Deserialize, JsonSchema, Default, Debug, Clone)]
#[kube(
    kind = "BatteryCluster",
    group = "batteriesincl.com",
    shortname = "bc",
    version = "v1",
    status = "BatteryClusterStatus"
)]
pub struct BatteryClusterSpec {
    pub account: String,
}

pub async fn is_crd_installed(client: Client) -> bool {
    let crds: Api<CustomResourceDefinition> = Api::all(client);
    debug!("Trying to get the crd. If it's there we'll continue on");
    crds.get(DEFAULT_CRD_NAME).await.is_ok()
}

pub async fn is_cluster_installed(client: Client) -> bool {
    Api::<BatteryCluster>::all(client)
        .get(DEFAULT_CLUSTER_NAME)
        .await
        .is_ok()
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

const DEFAULT_CLUSTER_NAME: &str = "default-cluster";
const DEFAULT_ACCOUNT_NAME: &str = "test-account";

pub fn default_cluster() -> BatteryCluster {
    BatteryCluster::new(
        DEFAULT_CLUSTER_NAME,
        BatteryClusterSpec {
            account: DEFAULT_ACCOUNT_NAME.into(),
        },
    )
}

pub async fn ensure_default_cluster(client: Client) -> Result<()> {
    if is_cluster_installed(client.clone()).await {
        Ok(())
    } else {
        let sa: Api<BatteryCluster> = Api::all(client);
        let params = PatchParams::apply("battery_operator").force();
        let patch = Patch::Apply(json!(&default_cluster()));
        Ok(sa
            .patch(DEFAULT_CLUSTER_NAME, &params, &patch)
            .await
            .map(|_| ())?)
    }
}
