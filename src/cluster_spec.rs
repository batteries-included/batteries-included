#![allow(clippy::default_trait_access)]
#![allow(clippy::field_reassign_with_default)]

use crate::error::BatteryError;
use k8s_openapi::apiextensions_apiserver::pkg::apis::apiextensions::v1::CustomResourceDefinition;

use kube::{
    api::{Api, PatchParams},
    client::Client,
};

use tracing::debug;

use kube::CustomResource;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

const DEFAULT_CRD_NAME: &str = "batteryclusters.batteriesincluded.company";

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone)]
pub enum GeneralStatus {
    RUNNING,
    STARTING,
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone)]
pub struct BatteryClusterStatus {
    current_status: GeneralStatus,
}

#[derive(CustomResource, Serialize, Deserialize, JsonSchema, Default, Debug, Clone)]
#[kube(kind = "BatteryCluster", group = "batteriesincluded.company", version = "v1")]
pub struct BatteryClusterSpec {
    pub account: String,
}

pub async fn is_crd_installed(client: Client) -> bool {
    let crds: Api<CustomResourceDefinition> = Api::all(client);
    debug!("Trying to get the crd. If it's there we'll continue on");
    match crds.get(DEFAULT_CRD_NAME).await {
        Ok(_) => true,
        Err(e) => {
            debug!("Got {:?} while trying to check if crd is installed", e);
            false
        }
    }
}

pub async fn install_crd(client: Client) -> Result<(), BatteryError> {
    if is_crd_installed(client.clone()).await {
        Ok(())
    } else {
        let crds: Api<CustomResourceDefinition> = Api::all(client);
        let params = PatchParams::apply("battery_operator").force();
        debug!("Installing CRD.");
        Ok(crds
            .patch(
                DEFAULT_CRD_NAME,
                &params,
                serde_yaml::to_vec(&BatteryCluster::crd())?,
            )
            .await
            .map(|_| {
                debug!("Successfully installed CRD.");
            })?)
    }
}
