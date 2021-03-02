use std::time::Duration;

use actix::prelude::*;
use actix_broker::{BrokerIssue, BrokerSubscribe, SystemBroker};
use common::cluster_spec::ensure_crd;
use kube::client::Client as KubeClient;
use tracing::debug;

use crate::actors::core_messages::NamespacePresentMessage;

use super::core_messages::CrdPresentMessage;
pub struct CrdDependencyActor {
    kube_client: KubeClient,
    installed: bool,
}

impl CrdDependencyActor {
    pub fn new(kube_client: KubeClient) -> Self {
        Self {
            kube_client,
            installed: false,
        }
    }
}

#[derive(Clone, Debug)]
pub struct TryStart;

impl Message for TryStart {
    type Result = ();
}

impl Actor for CrdDependencyActor {
    type Context = Context<Self>;
    fn started(&mut self, ctx: &mut Self::Context) {
        self.subscribe_system_async::<NamespacePresentMessage>(ctx);
    }
}

impl Handler<NamespacePresentMessage> for CrdDependencyActor {
    type Result = ();
    fn handle(&mut self, _msg: NamespacePresentMessage, ctx: &mut Self::Context) -> Self::Result {
        // Once we hear that the controller should start
        ctx.address().do_send(TryStart);
    }
}

impl Handler<TryStart> for CrdDependencyActor {
    type Result = ();
    fn handle(&mut self, _msg: TryStart, ctx: &mut Self::Context) -> Self::Result {
        let kc = self.kube_client.clone();
        ctx.wait(
            async {
                let res = ensure_crd(kc).await;
                res.is_ok()
            }
            .into_actor(self)
            .map(|install_success, this, en_ctx| {
                this.installed |= install_success;

                if install_success {
                    this.issue_sync::<SystemBroker, _>(CrdPresentMessage, en_ctx);
                }

                if !this.installed {
                    debug!("CustomResourceDefinition not installed for some reason. retrying in 5 seconds.");
                    en_ctx.run_later(Duration::from_millis(5000), move |act, c| {
                        // Check again in case someone else requested we retry.
                        if !act.installed {
                            debug!("Retrying crd install now.");
                            c.address().do_send(TryStart)
                        }
                    });
                }
            }),
        );
    }
}
