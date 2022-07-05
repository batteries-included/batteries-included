use std::{any::type_name, convert::TryFrom, fmt::Debug, time::Duration};

use async_trait::async_trait;
use common::kube::{
    api::{Patch, PatchParams},
    client::Client,
    core::ErrorResponse,
    Api, Config as KubeConfig, CustomResourceExt, Error as KubeError, Resource, ResourceExt,
};
use common::{
    cluster_spec::BatteryCluster,
    defaults,
    error::{BatteryError, Result},
};
use serde::{de::DeserializeOwned, Serialize};
use tracing::{debug, field, info, info_span, instrument, trace, Instrument, Span};

/// Helper trait for a get-or-replace style API to "ensure" the resource is synced to k8s
/// Polling for the resource to be ready is about all we have.
#[async_trait]
pub trait EnsureExists<T> {
    /// Amount of time to wait before checking for object creation
    const WAIT_START: Duration = Duration::from_millis(50);
    /// The backoff is exponential, so this is the maximum amount of time to wait before giving up
    const WAIT_MAX: Duration = Duration::from_secs(10);

    /// This function polls the k8s API for the object until it is found, or the timeout is reached.
    async fn ensure_exists(&self, obj: &T) -> Result<T>;
}

#[async_trait]
impl<T: Resource> EnsureExists<T> for Api<T>
where
    T: Serialize + DeserializeOwned,
    T: Clone + Debug + Sync + Send + 'static,
{
    #[instrument(
        skip(self, obj),
        fields(kind = type_name::<T>().rsplit_once(':').unwrap().1, name)
    )]
    async fn ensure_exists(&self, obj: &T) -> Result<T> {
        let name = obj
            .meta()
            .name
            .clone()
            .ok_or(BatteryError::UnexpectedNone)?;
        Span::current().record("name", &name.as_str());

        let mut wait_duration = Self::WAIT_START;
        let wait_span = info_span!("waiting", max = ?Self::WAIT_MAX, uid=field::Empty);

        let pp = PatchParams::apply("battery-operated").force();
        let patch = Patch::Apply(&obj);

        async move {
            trace!(?patch, "Sending PATCH");
            let from_patch = self.patch(&name, &pp, &patch).in_current_span().await?;
            // if patch succeeded, we (ostensibly) have a version
            let version = from_patch
                .resource_version()
                .expect("PATCH succeeded, but no version");
            loop {
                // we do the wait first because it's 50ms and probably enough to help? anecdata says yes
                debug!(next_wait=?wait_duration, "Waiting for Visible");
                // wait a bit, then extend our wait - but don't blow the timeout the first go
                tokio::time::sleep(wait_duration).await;
                wait_duration += wait_duration;
                if wait_duration >= 2 * Self::WAIT_MAX {
                    return Err(BatteryError::Timeout);
                }

                // see if the thing is there yet
                let result = self.get(&name).in_current_span().await;
                match result {
                    Ok(thing) if thing.resource_version().as_ref() == Some(&version) => {
                        info!(?thing, "Found");
                        return Ok(thing);
                    }
                    // NotFound or Gone (because we used a version) is OK, but we need to retry
                    Err(KubeError::Api(ErrorResponse {
                        code: 404 | 410, ..
                    })) => {
                        debug!("Not found yet");
                    }
                    _ => continue,
                }
            }
        }
        .instrument(wait_span)
        .await
    }
}

/// Set up Batteries Included on an existing Kubernetes installation.
#[derive(Debug, clap::Parser)]
pub struct BootstrapArgs {}

impl BootstrapArgs {
    #[instrument(target = "bootstrap", level = "debug", skip(self), fields(url=field::Empty, ns=field::Empty))]
    pub async fn run(self) -> Result<()> {
        // Connect to kubernetes
        let config = KubeConfig::infer().in_current_span().await?;
        Span::current().record("url", &config.cluster_url.to_string().as_str());
        let client = Client::try_from(config)?;

        // ensure we have a namespace set up
        let api = Api::all(client.clone());
        let ns = api
            .ensure_exists(&defaults::namespace())
            .in_current_span()
            .await?;

        // go ahead and save this bad boy for later
        let ns_name = ns
            .meta()
            .name
            .as_ref()
            .ok_or(BatteryError::UnexpectedNone)?;
        Span::current().record("ns", &ns_name.as_str());

        // now, samesies for the service account
        let api = Api::namespaced(client.clone(), ns_name);
        let _sa = api
            .ensure_exists(&defaults::service_account())
            .in_current_span()
            .await?;

        // once more, for the CRBs in the back!
        let api = Api::all(client.clone());
        let _crb = api
            .ensure_exists(&defaults::cluster_binding())
            .in_current_span()
            .await?;

        // oh what fun, there's CRDs too
        let mut crd_data = BatteryCluster::crd();
        crd_data.meta_mut().name = Some(defaults::CRD_NAME.to_string());
        let api = Api::all(client.clone());
        let _crd = api.ensure_exists(&crd_data).in_current_span().await?;

        // TODO: these definitely need configurables...
        let mut bc_data = BatteryCluster::default();
        bc_data.meta_mut().namespace = Some(ns_name.to_string());
        let api = Api::all(client.clone());
        let _bc = api.ensure_exists(&bc_data).in_current_span().await?;

        Ok(())
    }
}
