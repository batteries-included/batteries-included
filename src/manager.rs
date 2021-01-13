#![allow(clippy::needless_pass_by_value)]
#![allow(clippy::missing_const_for_fn)]

use crate::cluster_spec::BatteryCluster;
use crate::error::BatteryError;

use futures::{future::BoxFuture, FutureExt, StreamExt};
use k8s_openapi::apiextensions_apiserver::pkg::apis::apiextensions::v1::CustomResourceDefinition;
use kube_runtime::controller::{Context, Controller, ReconcilerAction};
use prometheus::{register_int_counter, IntCounter};
use std::time::Duration;

use kube::{
    api::{Api, ListParams},
    client::Client,
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

#[derive(Clone)]
pub struct State {
    client: Client,
    metrics: Metrics,
}

async fn reconcile(
    _cluster: BatteryCluster,
    _ctx: Context<State>,
) -> Result<ReconcilerAction, BatteryError> {
    Ok(ReconcilerAction {
        requeue_after: Some(Duration::from_secs(30)),
    })
}

fn error_policy(_error: &BatteryError, _ctx: Context<State>) -> ReconcilerAction {
    ReconcilerAction {
        requeue_after: Some(Duration::from_secs(1)),
    }
}

pub async fn check_crd(client: Client) -> Result<(), BatteryError> {
    let crds: Api<CustomResourceDefinition> = Api::all(client.clone());
    let crd_name = "batteryclusters.batteriesincluded.company";
    Ok(crds.get(crd_name).await.map(|_| ())?)
}
pub struct Manager {
    pub state: State,
    pub drainer: BoxFuture<'static, ()>,
}
impl Manager {
    pub async fn new(client: Client) -> Result<Self, BatteryError> {
        check_crd(client.clone()).await?;
        let state = State {
            client: client.clone(),
            metrics: Metrics::new(),
        };
        let clusters: Api<BatteryCluster> = Api::all(client);
        let context = Context::new(state.clone());

        let drainer = Controller::new(clusters, ListParams::default())
            .run(reconcile, error_policy, context)
            .filter_map(|x| async move { std::result::Result::ok(x) })
            .for_each(|_x| futures::future::ready(()))
            .boxed();
        Ok(Self { state, drainer })
    }
}
