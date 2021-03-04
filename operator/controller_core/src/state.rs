use crate::{
    cs_client::{ConfigFetcher, ControlServerClient},
    metrics::ControllerMetrics,
    prometheus::PrometheusManager,
};
use common::{
    cluster_spec::{BatteryCluster, BatteryClusterStatus, ClusterState, DEFAULT_NAMESPACE},
    cs_types::AdoptionConfig,
    error::{BatteryError, Result},
};
use kube::{api::PostParams, client::Client as KubeClient, Api};
use tracing::{debug, info, warn};

pub struct ControllerState {
    pub kube_client: KubeClient,
    pub ctrl_client: ControlServerClient,
    pub metrics: ControllerMetrics,
}

impl ControllerState {
    pub async fn start(&self, cluster: &BatteryCluster) -> Result<()> {
        Ok(self
            .set_status(&cluster, BatteryClusterStatus::default())
            .await?)
    }

    pub async fn check_adopt(&self, cluster: &BatteryCluster) -> Result<bool> {
        let status = cluster
            .status
            .as_ref()
            .ok_or(BatteryError::UnexpectedNone)?;

        let cluster_id = &cluster.spec.registered_cluster_id;

        debug!(
            cluster=?cluster,
            "Checking if cluster is adopted in the control server",
        );
        let adopted_config: AdoptionConfig = self.ctrl_client.adoption_config(cluster_id).await?;

        if adopted_config.is_adopted {
            let new_status = BatteryClusterStatus {
                current_state: ClusterState::Running,
                ..status.clone()
            };
            info!(
                cluster=? cluster,
                old_status=? status,
                new_status=? new_status,
                "Detected change in adoption state. Changing status"
            );
            self.set_status(cluster, new_status).await?;
        }
        Ok(adopted_config.is_adopted)
    }

    pub async fn sync_services(&self, cluster: &BatteryCluster) -> Result<()> {
        debug!(
            cluster=?cluster,
            "Preparing to sync all services.",
        );
        let cluster_id = &cluster.spec.registered_cluster_id;
        let running_set = self.ctrl_client.running_set_config(cluster_id).await?;

        debug!(running_set=?running_set, "Got running set");

        // This is the main reconcile loop of a running controller.
        // TODO: generalize this into events sent to running processes ala erlang.
        for (svc_name, &running) in running_set.iter() {
            match svc_name.as_str() {
                "monitoring" => {
                    let pom_manager = PrometheusManager::new(cluster_id.clone());
                    pom_manager
                        .sync(running, self.kube_client.clone(), &self.ctrl_client)
                        .await?;
                }
                _ => {
                    warn!("Got unexpected service name. {:?}", svc_name)
                }
            }
        }
        Ok(())
    }

    async fn set_status(
        &self,
        cluster: &BatteryCluster,
        status: BatteryClusterStatus,
    ) -> Result<()> {
        let clusters: Api<BatteryCluster> =
            Api::namespaced(self.kube_client.clone(), DEFAULT_NAMESPACE);

        if let Some(name) = cluster.metadata.name.as_ref() {
            let pp = PostParams::default();
            let new_cluster = BatteryCluster {
                status: Some(status),
                ..cluster.clone()
            };
            clusters
                .replace_status(name, &pp, serde_json::to_vec(&new_cluster)?)
                .await?;
        }
        Ok(())
    }
}
