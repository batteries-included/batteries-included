#![allow(clippy::needless_pass_by_value)]
#![allow(clippy::missing_const_for_fn)]

use std::time::Duration;

use futures::{future::BoxFuture, FutureExt, StreamExt};
use kube::{
    api::{Api, ListParams, PostParams},
    client::Client as KubeClient,
};
use kube_runtime::controller::{Context, Controller, ReconcilerAction};
use prometheus::{register_int_counter, IntCounter};
use tracing::{debug, info, warn};

use crate::{
    cluster_spec::{
        ensure_crd, ensure_namespace, BatteryCluster, BatteryClusterStatus, ClusterState,
        DEFAULT_NAMESPACE,
    },
    cs_client::ControlServerClient,
    error::{BatteryError, BatteryError::BadRegistration, Result},
};

#[derive(Clone)]
pub struct Metrics {
    pub reconcile_called: IntCounter,
}
impl Metrics {
    pub fn new() -> Self {
        Self {
            reconcile_called: register_int_counter!("reconcile_called", "Reconcile Called")
                .unwrap(),
        }
    }
}

pub struct State {
    pub kube_client: KubeClient,
    pub ctrl_client: ControlServerClient,
    pub metrics: Metrics,
}

impl State {
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

    async fn check_adopt(&self, cluster: &BatteryCluster) -> Result<bool> {
        let status = cluster
            .status
            .as_ref()
            .ok_or(BatteryError::UnexpectedNone)?;

        let cluster_id = &status
            .registered_cluster_id
            .as_ref()
            .ok_or(BatteryError::UnexpectedNone)?;
        debug!(
            cluster=?cluster,
            "Checking if cluster is adoped in the control server",
        );
        let adopted_config = self.ctrl_client.adoption_config(cluster_id).await?;

        if adopted_config.is_adopted {
            let new_status = BatteryClusterStatus {
                current_state: ClusterState::Starting,
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

    async fn register(&self, cluster: &BatteryCluster) -> Result<String> {
        // Send the request to the control server over rest http.
        let reg_response = self
            .ctrl_client
            .register(cluster.metadata.uid.clone())
            .await?;
        // Extract the new id or return a bad reg error.
        let new_id = reg_response.id.ok_or(BadRegistration)?;
        self.set_status(
            cluster,
            BatteryClusterStatus {
                current_state: ClusterState::AwaitingAdoption,
                registered_cluster_id: Some(new_id.to_string()),
            },
        )
        .await?;

        Ok(new_id)
    }
}

async fn reconcile(cluster: BatteryCluster, ctx: Context<State>) -> Result<ReconcilerAction> {
    // Extract the metrics we'll need these while running.
    let state = ctx.get_ref();
    let met = &state.metrics;
    // We got called once.
    met.reconcile_called.inc();

    debug!(cluster=?cluster);

    match &cluster.status {
        None => {
            state
                .set_status(&cluster, BatteryClusterStatus::default())
                .await?;
        }
        Some(status) => match status.current_state {
            ClusterState::Unregistered => {
                state.register(&cluster).await?;
            }
            ClusterState::AwaitingAdoption => {
                state.check_adopt(&cluster).await?;
            }
            _ => {
                info!("Unhandled status. Assuming this is ok");
            }
        },
    };

    Ok(ReconcilerAction {
        requeue_after: Some(Duration::from_secs(30)),
    })
}

fn error_policy(error: &BatteryError, _ctx: Context<State>) -> ReconcilerAction {
    warn!("Error: {:?}", error);
    ReconcilerAction {
        requeue_after: Some(Duration::from_secs(1)),
    }
}

pub struct Manager {
    pub context: Context<State>,
    pub drainer: BoxFuture<'static, ()>,
}
impl Manager {
    pub async fn new(kube_client: KubeClient, ctrl_server: ControlServerClient) -> Result<Self> {
        ensure_namespace(kube_client.clone()).await?;
        ensure_crd(kube_client.clone()).await?;
        let state = State {
            kube_client: kube_client.clone(),
            ctrl_client: ctrl_server,
            metrics: Metrics::new(),
        };

        // Context is mostly ARC. So use it for our keeping singular state.
        let context = Context::new(state);

        let clusters: Api<BatteryCluster> = Api::namespaced(kube_client, DEFAULT_NAMESPACE);
        let drainer = Controller::new(clusters, ListParams::default())
            .run(reconcile, error_policy, context.clone())
            .filter_map(|x| async move { std::result::Result::ok(x) })
            .for_each(|_x| futures::future::ready(()))
            .boxed();
        Ok(Self { context, drainer })
    }
}
