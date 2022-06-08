use std::{any::type_name, fmt::Debug, time::Duration};

use async_trait::async_trait;
use common::{
    cluster_spec::BatteryCluster,
    defaults,
    error::{BatteryError, Result},
    k8s_openapi::api::core::v1::Namespace,
};
use futures::{FutureExt, TryFutureExt};
use kube::{
    api::{Patch, PatchParams},
    client::Client,
    Api, CustomResourceExt, Resource,
};
use serde::{de::DeserializeOwned, Serialize};
use tokio::time::sleep;
use tracing::{debug, info, trace};

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
            .inspect(|result| {
                trace!(?result, "Inspecting result of initial get");
                if let Ok(thing) = result {
                    let ns = thing.meta().namespace.as_deref().unwrap_or("default");
                    let kind = type_name::<Self>().rsplit_once(':').unwrap().1;
                    info!(kind, %name, %ns, "Found!");
                }
            })
            .or_else(|e| {
                let name = name.clone();
                trace!(%e, "Error from get");
                info!(%name, "Not found, creating");
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

    // ensure its existence
    let api = Api::all(client.clone());
    let ns = defaults::namespace().ensure(&api).await?;

    // go ahead and save this bad boy for later
    let ns_name = ns
        .meta()
        .name
        .as_ref()
        .ok_or(BatteryError::UnexpectedNone)?;

    // now, samesies for the service account
    let api = Api::namespaced(client.clone(), ns_name);
    let _sa = defaults::service_account().ensure(&api).await?;

    // once more, for the CRBs in the back!
    let api = Api::all(client.clone());
    let _crb = defaults::cluster_binding().ensure(&api).await?;

    // oh what fun, there's CRDs too
    let mut crd_data = BatteryCluster::crd();
    crd_data.meta_mut().name = Some(defaults::CRD_NAME.to_string());
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
