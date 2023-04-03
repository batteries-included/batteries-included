use kube_client::core::DynamicObject;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use time::OffsetDateTime;
use tracing::debug;

pub async fn get_install_spec(url: url::Url) -> ::color_eyre::Result<InstallationSpec> {
    debug!("Getting install spec from {}", &url);
    let result = reqwest::get(url).await?.json::<InstallationSpec>().await?;

    // Re-wrap in Ok so that error's above go to the correct types.
    Ok(result)
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct InstallationSpec {
    pub initial_resource: HashMap<String, DynamicObject>,
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
    batteries: Vec<BatterySpec>,
    ceph_clusters: Vec<CephClusterSpec>,
    ceph_filesystems: Vec<CephFilesystemSpec>,
    ip_address_pools: Vec<IPAddressPoolSpec>,
    knative_services: Vec<KnativeServiceSpec>,
    notebooks: Vec<NotebookSpec>,
    postgres_clusters: Vec<PGClusterSpec>,
    redis_clusters: Vec<RedisClusterSpec>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct CephClusterSpec {
    name: String,

    data_dir: Option<String>,
    namespace: Option<String>,
    nodes: Option<Vec<Value>>,
    num_mgr: Option<i16>,
    num_mon: Option<i16>,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct CephFilesystemSpec {
    name: String,
    include_erasure_encoded: bool,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct IPAddressPoolSpec {
    name: String,
    subnet: String,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct KnativeServiceSpec {
    name: String,
    rollout_duration: Option<String>,
    containers: Option<Vec<Value>>,
    init_containers: Option<Vec<Value>>,
    env_values: Option<Vec<Value>>,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct NotebookSpec {
    name: String,
    image: String,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(rename_all = "snake_case")]
pub enum PGClusterType {
    Internal,
    Standard,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PGUserSpec {
    username: String,
    roles: Option<Vec<String>>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PGDatabaseSpec {
    name: String,
    owner: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(rename_all = "snake_case")]
pub enum PGCredentialCopyType {
    Dsn,
    UserPassword,
    UserPasswordHost,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PGCredentialCopySpec {
    username: String,
    namespace: String,
    format: PGCredentialCopyType,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct PGClusterSpec {
    name: String,
    num_instances: usize,
    postgres_version: String,
    team_name: String,

    #[serde(rename = "type")]
    cluster_type: PGClusterType,

    storage_size: String,

    users: Option<Vec<PGUserSpec>>,
    databases: Option<Vec<PGDatabaseSpec>>,
    credential_copies: Option<Vec<PGCredentialCopySpec>>,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[serde(rename_all = "snake_case")]
pub enum RedisClusterType {
    Internal,
    Standard,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct RedisClusterSpec {
    name: String,
    num_redis_isntances: usize,
    num_sentinel_instances: usize,
    cluster_type: RedisClusterType,

    id: Option<uuid::Uuid>,

    #[serde(with = "time::serde::iso8601::option")]
    inserted_at: Option<OffsetDateTime>,
    #[serde(with = "time::serde::iso8601::option")]
    updated_at: Option<OffsetDateTime>,
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
        assert!(!json.initial_resource.is_empty())
    }
}
