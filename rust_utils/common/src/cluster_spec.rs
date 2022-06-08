#![allow(clippy::default_trait_access)]
#![allow(clippy::field_reassign_with_default)]

use kube::CustomResource;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

use crate::defaults::{self, BatteryDefaults, APP_NAME};

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

impl Default for BatteryCluster {
    fn default() -> Self {
        let mut res = BatteryCluster::new(
            defaults::CLUSTER_NAME,
            BatteryClusterSpec {
                account: defaults::ACCOUNT_NAME.into(),
            },
        );
        res.apply_default_labels(APP_NAME);
        res
    }
}
