use actix_broker::BrokerIssue;
use kube::client::Client as KubeClient;

use crate::cs_client::ControlServerClient;
use actix::prelude::*;

use super::{cluster_controller::ClusterControllerActor, core_messages::StartMessage, crd::CrdDependencyActor, namespace::NamespaceDependencyActor};
use tracing::debug;

pub struct RootClusterActor {
    // kube_client: KubeClient,
    // ctrl_server: ControlServerClient,
    pub crd_actor: Addr<CrdDependencyActor>,
    pub namespace_actor: Addr<NamespaceDependencyActor>,
    pub cluster_controller_actor: Addr<ClusterControllerActor>,
}

impl RootClusterActor {
    pub fn new(kube_client: KubeClient) -> Self {
        Self {
            crd_actor: CrdDependencyActor::new(kube_client.clone()).start(),
            namespace_actor: NamespaceDependencyActor::new(kube_client.clone()).start(),
            cluster_controller_actor: ClusterControllerActor::new(kube_client.clone()).start(),
            // kube_client,
        }
    }
}

impl Actor for RootClusterActor {
    type Context = Context<Self>;
    fn started(&mut self, ctx: &mut Self::Context) {
        debug!("Root Cluster Actor started. Sending initial StartMessage to all actors.");
        self.issue_system_sync(StartMessage, ctx);
    }
}
