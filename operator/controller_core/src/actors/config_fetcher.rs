use std::collections::HashMap;

use actix::prelude::*;

use crate::cs_client::{ConfigFetcher, ControlServerClient};
use common::{cs_types::AdoptionConfig, error::Result};

struct GetAdoptionConfigMessage;
impl Message for GetAdoptionConfigMessage {
    type Result = Result<AdoptionConfig>;
}

struct GetRunningSetConfigMessage;
impl Message for GetRunningSetConfigMessage {
    type Result = Result<HashMap<String, bool>>;
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

impl Handler<GetAdoptionConfigMessage> for ConfigFetcherActor {
    type Result = ResponseFuture<Result<AdoptionConfig>>;

    fn handle(&mut self, _msg: GetAdoptionConfigMessage, _ctx: &mut Self::Context) -> Self::Result {
        let client = self.cs_client.clone();
        let cluster_id = self.cluster_id.clone();
        Box::pin(async move { client.adoption_config(&cluster_id).await })
    }
}

impl Handler<GetRunningSetConfigMessage> for ConfigFetcherActor {
    type Result = ResponseFuture<Result<HashMap<String, bool>>>;

    fn handle(
        &mut self,
        _msg: GetRunningSetConfigMessage,
        _ctx: &mut Self::Context,
    ) -> Self::Result {
        let client = self.cs_client.clone();
        let cluster_id = self.cluster_id.clone();
        Box::pin(async move { client.running_set_config(&cluster_id).await })
    }
}
