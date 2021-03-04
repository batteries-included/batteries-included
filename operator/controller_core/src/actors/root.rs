use actix_broker::{BrokerIssue, BrokerSubscribe};
use kube::client::Client as KubeClient;

use crate::cs_client::ControlServerClient;
use actix::prelude::*;

use super::{
    cluster_controller::ClusterControllerActor,
    core_messages::{
        DependenciesReadyMessage, KubeClusterStatusMessage, StartMessage,
    },
    crd::CrdDependencyActor,
    deps_ready::DepsReadyActor,
    namespace::NamespaceDependencyActor,
};
use tracing::debug;

pub struct RootClusterActor {
    kube_client: KubeClient,
    cs_client: ControlServerClient,
    cluster_id: Option<String>,
    pub crd_actor: Addr<CrdDependencyActor>,
    pub namespace_actor: Addr<NamespaceDependencyActor>,
    pub deps_ready_actor: Addr<DepsReadyActor>,
    pub cluster_controller_actor: Option<Addr<ClusterControllerActor>>,
}

impl RootClusterActor {
    pub fn new(kube_client: KubeClient, cs_client: ControlServerClient) -> Self {
        Self {
            crd_actor: CrdDependencyActor::new(kube_client.clone()).start(),
            namespace_actor: NamespaceDependencyActor::new(kube_client.clone()).start(),
            deps_ready_actor: DepsReadyActor.start(),
            cluster_controller_actor: None,
            kube_client,
            cs_client,
            cluster_id: None,
        }
    }
}

impl Actor for RootClusterActor {
    type Context = Context<Self>;
    fn started(&mut self, ctx: &mut Self::Context) {
        self.subscribe_system_async::<DependenciesReadyMessage>(ctx);
        self.subscribe_system_async::<KubeClusterStatusMessage>(ctx);
        debug!("Root Cluster Actor started. Sending initial StartMessage to all actors.");
        self.issue_system_async(StartMessage);
    }
}

impl Handler<DependenciesReadyMessage> for RootClusterActor {
    type Result = ();
    fn handle(&mut self, _msg: DependenciesReadyMessage, _ctx: &mut Self::Context) -> Self::Result {
        debug!("All dependencies ready starting ClusterControllerActor to watch the k8 crd.");
        // // Start the new actor.
        // // TODO: Should this be on it's own arbiter?
        // self.cluster_controller_actor =
        //     Some(ClusterControllerActor::new(self.kube_client.clone()).start());
    }
}

impl Handler<KubeClusterStatusMessage> for RootClusterActor {
    type Result = ();
    fn handle(&mut self, msg: KubeClusterStatusMessage, _ctx: &mut Self::Context) -> Self::Result {
        let KubeClusterStatusMessage(cluster) = msg;
        debug!("Got status update for cluster = {:?}", cluster);
    }
}
