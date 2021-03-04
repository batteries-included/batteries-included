use actix::prelude::*;
use actix_broker::{BrokerIssue, BrokerSubscribe};
use tracing::debug;

use super::core_messages::{CrdPresentMessage, DependenciesReadyMessage};
pub struct DepsReadyActor;

impl Actor for DepsReadyActor {
    type Context = Context<Self>;

    fn started(&mut self, ctx: &mut Self::Context) {
        self.subscribe_system_async::<CrdPresentMessage>(ctx);
    }
}

impl Handler<CrdPresentMessage> for DepsReadyActor {
    type Result = ();
    fn handle(&mut self, _msg: CrdPresentMessage, _ctx: &mut Self::Context) -> Self::Result {
        debug!("CRD is present about to tell everyone the dependencies are ready.");
        // After the CRD is installed then the
        // kube cluster is ok enough to start installing what we need
        self.issue_system_async(DependenciesReadyMessage);
        debug!("Told everyone");
    }
}
