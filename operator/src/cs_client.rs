use reqwest::Client;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use tracing::debug;

use crate::error::{BatteryError, Result};

#[derive(Debug, Clone)]
pub struct ControlServerClient {
    http_client: Client,
    base_url: String,
}

#[derive(Serialize, Deserialize, JsonSchema, Default, Debug, Clone)]
pub struct JsonKubeCluster {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub adopted: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub external_uid: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
struct JsonKubeClusterBody {
    kube_cluster: JsonKubeCluster,
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
struct ControlServerResponse<T> {
    data: T,
}
#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
struct ConfigWrapper<T> {
    id: String,
    path: String,
    content: T,
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
pub struct AdoptionConfig {
    pub is_adopted: bool,
}

impl ControlServerClient {
    pub fn new(base_url: String) -> Self {
        Self {
            http_client: Client::new(),
            base_url,
        }
    }

    pub async fn get_cluster(&self, id: &str) -> Result<JsonKubeCluster> {
        let url = self.base_url.clone() + "/api/kube_clusters/" + id;
        let request = self.http_client.get(&url);
        let response = request.send().await?;
        let payload = response
            .json::<ControlServerResponse<JsonKubeCluster>>()
            .await?;
        Ok(payload.data)
    }

    pub async fn register(&self, external_uid: Option<String>) -> Result<JsonKubeCluster> {
        let url = self.base_url.clone() + "/api/kube_clusters";
        let body = JsonKubeClusterBody {
            kube_cluster: JsonKubeCluster {
                external_uid,
                ..JsonKubeCluster::default()
            },
        };

        // Prepare the request.
        let request = self.http_client.post(&url).json(&body);
        let response = request.send().await?;
        let payload = response
            .json::<ControlServerResponse<JsonKubeCluster>>()
            .await?;

        debug!("Registration completed. payload = {:?}", payload);
        Ok(payload.data)
    }

    pub async fn adoption_config(&self, cluster_id: &str) -> Result<AdoptionConfig> {
        let url = self.base_url.clone() + "/api/kube_clusters/" + cluster_id + "/raw_configs";
        let request = self.http_client.get(&url).query(&[("path", "/adoption")]);
        let response = request.send().await?;
        let payload = response
            .json::<ControlServerResponse<Vec<ConfigWrapper<AdoptionConfig>>>>()
            .await?;
        let config = payload.data.first().ok_or(BatteryError::UnexpectedNone)?;
        Ok(config.content.clone())
    }
}
