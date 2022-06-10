use std::{any::type_name, borrow::Cow, fmt::Debug};

use async_trait::async_trait;
use common::{
    cluster_spec::BatteryCluster,
    defaults,
    error::{BatteryError, Result},
};
use futures::{FutureExt, StreamExt, TryFutureExt, TryStreamExt};
use kube::{
    api::{ListParams, Patch, PatchParams},
    client::Client,
    Api, CustomResourceExt, Resource,
};
use serde::{de::DeserializeOwned, Serialize};
use tracing::{debug, info, info_span, trace, trace_span, Instrument};

/// Helper trait for a get-or-replace style API to "ensure" the resource is synced to k8s
///
/// # Semantics
/// This subscribes to the WatchEvents for the type, then issues the create.
/// Upon receipt of _the very next watch event on a filtered channel_, this function returns.
/// The intent is to return only after the point the object is visible
#[async_trait]
pub trait EnsureExists:
    Resource + Unpin + Sync + Send + Sized + Clone + DeserializeOwned + Serialize + Debug + 'static
{
    /// Using the given `Api`, "get or create"
    /// This function returns when k8s fires the `WatchEvent::Added` for the object being created.
    async fn ensure_exists(self, api: &Api<Self>) -> Result<Self> {
        let name = self
            .meta()
            .name
            .clone()
            .map(Cow::from)
            .ok_or(BatteryError::UnexpectedNone)?;

        let kind = type_name::<Self>().rsplit_once(':').unwrap().1;
        let result = api
            .get(&name)
            .instrument(info_span!("lookup"))
            .inspect(|result| {
                trace!(?result, "Inspecting result of initial get");
                if let Ok(thing) = result {
                    let uid = thing.meta().uid.as_ref().expect("missing a UID");
                    info!(%uid, "Found");
                }
            })
            .or_else(|_e| {
                let name = name.clone();
                async move {
                    // Set up the watch params and let it rip, next thing out of that stream should be the requisite add
                    let lp = ListParams::default()
                        .timeout(10)
                        .fields(&format!("metadata.name={}", name));
                    let mut stream = api
                        .watch(&lp, "0")
                        .instrument(trace_span!("api watcher"))
                        .await?
                        .boxed();
                    let pp = PatchParams::apply("battery-operated").force();
                    let patch = Patch::Apply(&self);
                    let patch_result = api.patch(&name, &pp, &patch).await?;
                    let uid = patch_result.meta().uid.as_ref().expect("missing a UID");
                    stream.try_next().await?.expect("watch fired but got None");
                    info!(%uid, "Created");
                    Ok::<_, BatteryError>(patch_result)
                }
                .instrument(info_span!("create"))
            })
            .instrument(info_span!("ensure", %name, %kind))
            .await?;
        // dbg!(&result);
        Ok(result)
    }
}

impl<T> EnsureExists for T where
    T: Resource
        + Unpin
        + Sync
        + Send
        + Sized
        + Clone
        + DeserializeOwned
        + Serialize
        + Debug
        + 'static
{
}

pub async fn run() -> Result<()> {
    // Connect to kubernetes
    debug!("Connecting to kubernetes.");
    let client = Client::try_default().await?;

    // ensure its existence
    let api = Api::all(client.clone());
    let ns = defaults::namespace().ensure_exists(&api).await?;

    // go ahead and save this bad boy for later
    let ns_name = ns
        .meta()
        .name
        .as_ref()
        .ok_or(BatteryError::UnexpectedNone)?;

    // now, samesies for the service account
    let api = Api::namespaced(client.clone(), ns_name);
    let _sa = defaults::service_account().ensure_exists(&api).await?;

    // once more, for the CRBs in the back!
    let api = Api::all(client.clone());
    let _crb = defaults::cluster_binding().ensure_exists(&api).await?;

    // oh what fun, there's CRDs too
    let mut crd_data = BatteryCluster::crd();
    crd_data.meta_mut().name = Some(defaults::CRD_NAME.to_string());
    let api = Api::all(client.clone());
    let _crd = crd_data.ensure_exists(&api).await?;

    info!("CRD present creating cluster");
    // TODO: these definitely need configurables...
    let mut bc_data = BatteryCluster::default();
    bc_data.meta_mut().namespace = Some(ns_name.to_string());
    let api = Api::all(client.clone());
    let _bc = bc_data.ensure_exists(&api).await?;

    Ok(())
}
