use kube_client::core::DynamicObject;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use time::OffsetDateTime;

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct InstallationSpec {
    pub initial_resources: HashMap<String, DynamicObject>,
    pub kube_cluster: ClusterSpec,
    pub target_summary: StateSummarySpec,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct ClusterSpec {
    pub provider: ProviderType,
}

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
#[serde(rename_all = "snake_case")]
pub enum ProviderType {
    Kind,
    Provided,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct BatterySpec {
    group: String,
    #[serde(rename = "type")]
    battery_type: String,

    config: HashMap<String, Value>,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct StateSummarySpec {
    pub batteries: Vec<DynamicObject>,
    pub ip_address_pools: Vec<IPAddressPoolSpec>,
    pub knative_services: Vec<DynamicObject>,
    pub notebooks: Vec<DynamicObject>,
    pub postgres_clusters: Vec<DynamicObject>,
    pub ferret_services: Vec<DynamicObject>,
    pub redis_clusters: Vec<DynamicObject>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct IPAddressPoolSpec {
    pub name: String,
    pub subnet: String,

    pub id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    pub inserted_at: Option<OffsetDateTime>,

    #[serde(with = "time::serde::iso8601::option")]
    pub updated_at: Option<OffsetDateTime>,
}

#[cfg(test)]
mod tests {
    use std::{fs, path::PathBuf};

    use super::*;

    #[test]
    fn test_can_parse_example_static_install_spec() {
        let mut base = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        base.push("tests/resources/specs");
        base.push("dev.json");

        let contents =
            fs::read_to_string(base.as_path()).expect("Should have been able to read the file");

        let json: InstallationSpec = serde_json::from_str(&contents).expect("Should parse");
        assert!(!json.initial_resources.is_empty())
    }
}
