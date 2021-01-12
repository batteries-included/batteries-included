#![allow(clippy::default_trait_access)]
#![allow(clippy::field_reassign_with_default)]
#![allow(clippy::module_name_repetitions)]

use kube::CustomResource;
use serde::{Serialize, Deserialize};
use schemars::JsonSchema;

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
#[kube(
    kind = "BatteryCluster",
    group = "batteriesincluded.company",
    status = "BatteryClusterStatus",
    version = "v1",
    namespaced
)]
pub struct BatteryClusterSpec {
    name: String,
}