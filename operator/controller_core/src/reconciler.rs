use std::time::Duration;

use common::{
    cluster_spec::{BatteryCluster, ClusterState},
    error::Result,
};
use kube_runtime::controller::{Context, ReconcilerAction};
use tracing::{debug, info};

use crate::state::ControllerState;

pub async fn reconcile(cluster: BatteryCluster, ctx: Context<ControllerState>) -> Result<ReconcilerAction> {
    // Extract the metrics we'll need these while running.
    let state = ctx.get_ref();
    let met = &state.metrics;
    // We got called once.
    met.reconcile_called.inc();

    debug!(cluster=?cluster);

    match &cluster.status {
        None => {
            state.start(&cluster).await?;
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
                state.sync_services(&cluster).await?;
            }
        },
    };

    Ok(ReconcilerAction {
        requeue_after: Some(Duration::from_secs(30)),
    })
}
