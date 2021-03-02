use std::time::Duration;

use actix::prelude::*;
use actix_broker::{Broker,  SystemBroker};
use common::cluster_spec::{BatteryCluster, DEFAULT_NAMESPACE};
use futures::{future::BoxFuture, FutureExt, StreamExt};
use kube::{
    api::{Api, ListParams},
    client::Client as KubeClient,
};
use kube_runtime::{controller::ReconcilerAction, Controller};
use tracing::log::debug;

use super::core_messages::KubeClusterStatusMessage;
/// This is an actor that will start up a kube_runtime
/// controller watching all the BatteryCluster instances.
///
/// This is super overkill.
///
/// Other alternatives would be just polling. However kube_runtime's
///controller will be faster to respond to changes.
pub struct ClusterControllerActor {
    kube_client: KubeClient,
    drainer: BoxFuture<'static, ()>,
}

impl ClusterControllerActor {
    pub fn new(kube_client: KubeClient) -> Self {
        Self {
            kube_client,
            drainer: async {}.boxed(),
        }
    }
}

impl Actor for ClusterControllerActor {
    type Context = Context<Self>;

    fn started(&mut self, _ctx: &mut Self::Context) {
        debug!("Starting new kube_runtime controller for clusters");
        let clusters: Api<BatteryCluster> =
            Api::namespaced(self.kube_client.clone(), DEFAULT_NAMESPACE);

        self.drainer = Controller::new(clusters, ListParams::default())
            .run(
                // This is a simple function that will send the KubeClusterStatusMessage
                // and then tell the controller to sleep until the next thing changes.
                //
                // It has to go to the SystemBroker because we don't have access to self in the running
                // controller. Rust + kube_runtime refuse to work with anything other than a 'static future.
                |cluster, _| async {
                    Broker::<SystemBroker>::issue_async(KubeClusterStatusMessage(cluster));
                    Ok(ReconcilerAction {
                        requeue_after: Some(Duration::from_secs(5)),
                    })
                },
                |_: &std::io::Error, _| ReconcilerAction {
                    requeue_after: Some(Duration::from_secs(5)),
                },
                kube_runtime::controller::Context::new(()),
            )
            .for_each(|_| futures::future::ready(()))
            .boxed();
    }
}
