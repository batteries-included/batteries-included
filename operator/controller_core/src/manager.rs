#![allow(clippy::needless_pass_by_value)]
#![allow(clippy::missing_const_for_fn)]

use std::time::Duration;

use crate::{cs_client::ControlServerClient, reconciler, state::ControllerState};
use common::{
    cluster_spec::{ensure_crd, ensure_namespace, BatteryCluster, DEFAULT_NAMESPACE},
    error::{BatteryError, Result},
};
use futures::{future::BoxFuture, FutureExt, StreamExt};
use kube::{
    api::{Api, ListParams},
    client::Client as KubeClient,
};
use kube_runtime::controller::{Context, Controller, ReconcilerAction};
use tracing::warn;

use crate::metrics::ControllerMetrics;

fn error_policy(error: &BatteryError, _ctx: Context<ControllerState>) -> ReconcilerAction {
    warn!("Error: {:?}", error);
    ReconcilerAction {
        requeue_after: Some(Duration::from_secs(1)),
    }
}

pub struct Manager {
    pub context: Context<ControllerState>,
    pub drainer: BoxFuture<'static, ()>,
}
impl Manager {
    pub async fn new(kube_client: KubeClient, ctrl_server: ControlServerClient) -> Result<Self> {
        ensure_namespace(kube_client.clone()).await?;
        ensure_crd(kube_client.clone()).await?;
        let state = ControllerState {
            kube_client: kube_client.clone(),
            ctrl_client: ctrl_server,
            metrics: ControllerMetrics::new(),
        };

        // Context is mostly ARC. So use it for our keeping singular state.
        let context = Context::new(state);

        let clusters: Api<BatteryCluster> = Api::namespaced(kube_client, DEFAULT_NAMESPACE);
        let drainer = Controller::new(clusters, ListParams::default())
            .run(reconciler::reconcile, error_policy, context.clone())
            .filter_map(|x| async move { std::result::Result::ok(x) })
            .for_each(|_x| futures::future::ready(()))
            .boxed();
        Ok(Self { context, drainer })
    }
}
