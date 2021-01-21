#![allow(clippy::needless_pass_by_value)]
#![allow(clippy::missing_const_for_fn)]

use std::time::Duration;

use futures::{future::BoxFuture, FutureExt, StreamExt};
use kube::{
    api::{Api, ListParams},
    client::Client as KubeClient,
};
use kube_runtime::controller::{Context, Controller, ReconcilerAction};
use prometheus::{register_int_counter, IntCounter};
use tracing::{event, warn, Level};

use crate::{
    cluster_spec::{ensure_crd, ensure_namespace, BatteryCluster, DEFAULT_NAMESPACE},
    cs_client::ControlServerClient,
    error::BatteryError,
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

async fn reconcile(
    cluster: BatteryCluster,
    ctx: Context<State>,
) -> Result<ReconcilerAction, BatteryError> {
    // Extract the metrics we'll need these while running.
    let state = ctx.get_ref();
    let met = &state.metrics;
    // We got called once.
    met.reconcile_called.inc();

    let namespace = cluster.metadata.namespace.as_ref();

    event!(Level::DEBUG,cluster = ?cluster, namespace=?namespace);
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
    pub async fn new(
        kube_client: KubeClient,
        ctrl_server: ControlServerClient,
    ) -> Result<Self, BatteryError> {
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
