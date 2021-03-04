use reqwest::Client;
use tracing::debug;

use crate::{
    cs_types::{ControlServerResponse, JsonKubeCluster, JsonKubeClusterBody},
    error::Result,
};

pub struct ClusterRegister {
    base_url: String,
    http_client: Client,
}

impl ClusterRegister {
    pub fn new(base_url: String) -> Self {
        Self {
            base_url,
            http_client: Client::new(),
        }
    }
    pub async fn register(&self) -> Result<JsonKubeCluster> {
        let url = self.base_url.clone() + "/api/kube_clusters";
        let body = JsonKubeClusterBody {
            kube_cluster: JsonKubeCluster {
                adopted: Some(false),
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
}
