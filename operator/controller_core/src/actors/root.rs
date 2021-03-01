use common::error::Result;
use kube::client::Client as KubeClient;

use crate::cs_client::ControlServerClient;
use actix::prelude::*;

use common::cluster_spec::{ensure_crd, ensure_namespace};

#[derive(Debug, Clone, Copy)]
pub enum RootClusterStatus {
    Uninitialized,
    NamespacePresent,
    Initialized
}

struct TryStart;

impl Message for TryStart {
    type Result = RootClusterStatus;
}

struct RootClusterActor {
    status: RootClusterStatus,
    kube_client: KubeClient,
    ctrl_server: ControlServerClient,
}

impl RootClusterActor {
    pub fn new(kube_client: KubeClient, ctrl_server: ControlServerClient) -> Self {
        Self {
            status: RootClusterStatus::Uninitialized,
            kube_client,
            ctrl_server,
        }
    }
}

impl Actor for RootClusterActor {
    type Context = Context<Self>;
}

impl Handler<TryStart> for RootClusterActor {
    type Result = AtomicResponse<Self, RootClusterStatus>;

    fn handle(&mut self, _msg: TryStart, _ctx: &mut Self::Context) -> Self::Result {
        match self.status {
            RootClusterStatus::Uninitialized => {
                let kc = self.kube_client.clone();
                AtomicResponse::new(Box::pin(
                    async {
                        ensure_namespace(kc).await?;
                        Ok(())
                    }
                    .into_actor(self)
                    .map(|res: Result<()>, this, _| {
                        if res.is_ok() {
                            this.status = RootClusterStatus::NamespacePresent
                        }
                        this.status
                    }),
                ))
            }
            RootClusterStatus::NamespacePresent => {
                let kc = self.kube_client.clone();
                AtomicResponse::new(Box::pin(
                    async {
                        ensure_crd(kc).await?;
                        Ok(())
                    }
                    .into_actor(self)
                    .map(|res: Result<()>, this, _| {
                        if res.is_ok() {
                            this.status = RootClusterStatus::Initialized
                        }
                        this.status
                    }),
                ))
            }
            RootClusterStatus::Initialized => AtomicResponse::new(Box::pin(
                async {}.into_actor(self).map(|_, this, _| this.status),
            )),
        }
    }
}
