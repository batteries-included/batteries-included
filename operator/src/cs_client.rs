use reqwest::Client;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};
use tracing::debug;

use crate::error::Result;

#[derive(Debug, Clone)]
pub struct ControlServerClient {
    http_client: Client,
    base_url: String,
}

#[derive(Serialize, Deserialize, JsonSchema, Default, Debug, Clone)]
pub struct JsonKubeCluster {
    pub adopted: Option<bool>,
    pub external_uid: Option<String>,
    pub id: Option<String>,
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
struct JsonKubeClusterBody {
    kube_cluster: JsonKubeCluster,
}

#[derive(Serialize, Deserialize, JsonSchema, Debug, Clone, Default)]
struct JsonKubeClusterResponse {
    data: JsonKubeCluster,
}

impl ControlServerClient {
    pub fn new(base_url: String) -> Self {
        Self {
            http_client: Client::new(),
            base_url,
        }
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
        let payload = response.json::<JsonKubeClusterResponse>().await?;

        debug!("Registration completed. payload = {:?}", payload);
        Ok(payload.data)
    }
}
