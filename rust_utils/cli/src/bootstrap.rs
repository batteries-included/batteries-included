use std::{fmt::Debug, time::Duration};

use async_trait::async_trait;
use common::{
    cluster_spec::{BatteryCluster, DEFAULT_CRD_NAME},
    error::{BatteryError, Result},
    k8s_openapi::{api::core::v1::Namespace, Metadata},
    namespace::DEFAULT_NAMESPACE,
    permissions::{cluster_binding, service_account},
};
use futures::TryFutureExt;
use kube::{
    api::{Patch, PatchParams},
    client::Client,
    Api, CustomResourceExt, Resource,
};
use serde::{de::DeserializeOwned, Serialize};
use tokio::time::sleep;
use tracing::{debug, info};

pub trait ToPatch: Serialize + Sized {
    fn to_patch(&self) -> Patch<Self>;
}

impl ToPatch for Namespace {
    fn to_patch(&self) -> Patch<Self> {
        todo!();
    }
}

#[async_trait]
pub trait Ensure:
    Resource + Sync + Send + Sized + Clone + DeserializeOwned + Serialize + Debug
{
    /// Get or create `Self` with the given `Api`
    async fn ensure(self, api: &Api<Self>) -> Result<Self> {
        let name = self
            .meta()
            .name
            .clone()
            .ok_or(BatteryError::UnexpectedNone)?;

        let result = api
            .get(&name)
            .or_else(|e| {
                let name = name.clone();
                debug!(%e, "Received error during get");
                info!(?name, "Not found, creating");
                let pp = PatchParams::apply("battery-operated");
                let patch = Patch::Apply(&self);
                async move { api.patch(&name, &pp, &patch).await }
            })
            .await?;
        // dbg!(&result);
        Ok(result)
    }
}

impl<T> Ensure for T where
    T: Resource + Sync + Send + Sized + Clone + DeserializeOwned + Serialize + Debug
{
}

pub async fn run() -> Result<()> {
    // Connect to kubernetes
    debug!("Connecting to kubernetes.");
    let client = Client::try_default().await?;

    // build the namespace we expect to use
    let mut data = Namespace::default();
    let m = data.metadata_mut();
    m.name = Some(DEFAULT_NAMESPACE.to_string());

    // ensure its existence
    let api = Api::all(client.clone());
    let ns = data.ensure(&api).await?;

    // go ahead and save this bad boy for later
    let ns_name = ns
        .meta()
        .name
        .as_ref()
        .ok_or(BatteryError::UnexpectedNone)?;

    // now, samesies for the service account
    let mut data = service_account();
    data.meta_mut().namespace = Some(ns_name.to_string());

    let api = Api::namespaced(client.clone(), ns_name);
    let _sa = data.ensure(&api).await?;

    // once more, for the CRBs in the back!
    let mut data = cluster_binding();
    data.meta_mut().namespace = Some(ns_name.to_string());
    let api = Api::all(client.clone());
    let _crb = data.ensure(&api).await?;

    // oh what fun, there's CRDs too
    let mut crd_data = BatteryCluster::crd();
    crd_data.meta_mut().name = Some(DEFAULT_CRD_NAME.to_string());
    let api = Api::all(client.clone());
    let _crd = crd_data.ensure(&api).await?;

    // Hack alert. It seems like there's some delay between registering a crd and
    // being able to use it. so sleep for a while. This should be better handled
    // with retries.... Lame.
    sleep(Duration::from_millis(2000)).await;

    info!("CRD present creating cluster");
    // TODO: these definitely need configurables...
    let mut bc_data = BatteryCluster::default();
    bc_data.meta_mut().namespace = Some(ns_name.to_string());
    let api = Api::all(client.clone());
    let _bc = bc_data.ensure(&api).await?;

    Ok(())
}
