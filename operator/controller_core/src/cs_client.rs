use async_trait::async_trait;
use reqwest::Client;
use serde::de::DeserializeOwned;
use std::collections::HashMap;
use tracing::debug;

use common::{
    cs_types::{AdoptionConfig, ConfigWrapper, ControlServerResponse, JsonKubeCluster},
    error::Result,
};

#[derive(Debug, Clone)]
pub struct ControlServerClient {
    http_client: Client,
    base_url: String,
}

#[async_trait]
pub trait ClusterFetcher {
    async fn get_cluster(&self, id: &str) -> Result<JsonKubeCluster>;
}

#[async_trait]
impl ClusterFetcher for ControlServerClient {
    async fn get_cluster(&self, id: &str) -> Result<JsonKubeCluster> {
        let url = self.base_url.clone() + "/api/kube_clusters/" + id;
        let request = self.http_client.get(&url);
        let response = request.send().await?;
        let payload = response
            .json::<ControlServerResponse<JsonKubeCluster>>()
            .await?;
        Ok(payload.data)
    }
}

#[async_trait]
pub trait ConfigFetcher {
    async fn adoption_config(&self, cluster_id: &str) -> Result<AdoptionConfig>;
    async fn running_set_config(&self, cluster_id: &str) -> Result<HashMap<String, bool>>;
    async fn prometheus_main_config(&self, cluster_id: &str) -> Result<serde_json::Value>;
}

#[async_trait]
impl ConfigFetcher for ControlServerClient {
    async fn adoption_config(&self, cluster_id: &str) -> Result<AdoptionConfig> {
        self.get_config(cluster_id, "/adoption").await
    }

    async fn running_set_config(&self, cluster_id: &str) -> Result<HashMap<String, bool>> {
        self.get_config(cluster_id, "/running_set").await
    }

    async fn prometheus_main_config(&self, cluster_id: &str) -> Result<serde_json::Value> {
        self.get_config(cluster_id, "/prometheus/main").await
    }
}

impl ControlServerClient {
    #[must_use]
    pub fn new(base_url: String) -> Self {
        Self {
            http_client: Client::new(),
            base_url,
        }
    }

    async fn get_config<T: Clone + DeserializeOwned>(
        &self,
        cluster_id: &str,
        path: &str,
    ) -> Result<T> {
        let url = self.base_url.clone() + "/api/kube_clusters/" + cluster_id + "/configs" + path;
        let request = self.http_client.get(&url);
        let response = request.send().await?;
        debug!(
            url=?url, response=?response,
            "Fetching config complete"
        );
        let payload = response
            .json::<ControlServerResponse<ConfigWrapper<T>>>()
            .await?;
        let config = payload.data;
        Ok(config.content)
    }
}
