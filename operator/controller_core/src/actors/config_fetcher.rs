use actix::prelude::*;
use actix_broker::{BrokerIssue, BrokerSubscribe, SystemBroker};

use crate::cs_client::{AdoptionConfig, ConfigFetcher, ControlServerClient};
use common::error::Result;

struct GetAdoptionConfig;

impl Message for GetAdoptionConfig {
    type Result = Result<AdoptionConfig>;
}

pub struct ConfigFetcherActor {
    cs_client: ControlServerClient,
    cluster_id: String,
}

impl ConfigFetcherActor {
    pub fn new(cs_client: ControlServerClient, cluster_id: String) -> Self {
        Self {
            cs_client,
            cluster_id,
        }
    }
}

impl Actor for ConfigFetcherActor {
    type Context = Context<Self>;
}

impl Handler<GetAdoptionConfig> for ConfigFetcherActor {
    type Result = ResponseFuture<Result<AdoptionConfig>>;

    fn handle(&mut self, _msg: GetAdoptionConfig, _ctx: &mut Self::Context) -> Self::Result {
        let client = self.cs_client.clone();
        let cluster_id = self.cluster_id.clone();
        Box::pin(async move { client.adoption_config(&cluster_id).await })
    }
}
