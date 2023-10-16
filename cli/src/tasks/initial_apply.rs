use eyre::{bail, ContextCompat, Result};
use futures::{stream, StreamExt};
use std::collections::HashMap;
use tracing::{debug, info};

use kube_client::{
    api::{Patch, PatchParams},
    core::{DynamicObject, GroupVersionKind},
    discovery::{ApiCapabilities, ApiResource, Scope},
    Api, Client, Discovery,
};
use tokio::time::{sleep, Duration};

pub async fn initial_apply(
    kube_client: Client,
    overwrite_resources: bool,
    initial_resources: HashMap<String, DynamicObject>,
) -> Result<()> {
    let apply_params = PatchParams::apply("bcli").force();
    let mut retries = 20;
    let mut unsynced = initial_resources;

    while retries >= 0 && !unsynced.is_empty() {
        retries -= 1;
        // We re-create the discovery every time we reset the
        // retry count to allow for us to create so many crds at the same time and
        // we need discovery to catch up.
        let discovery = Discovery::new(kube_client.clone()).run().await?;

        info!(
            "Initial apply retries = {:?} unsynced.len() = {:?}",
            retries,
            unsynced.len()
        );

        unsynced = stream::iter(unsynced)
            .filter_map(|(path, resource)| async {
                // Try and create the resource via apply.
                // Sometimes this will fail.
                // When that happens we need to retry that resource until it works.
                let apply_result = initial_apply_single(
                    kube_client.clone(),
                    &discovery,
                    &apply_params,
                    overwrite_resources,
                    resource.clone(),
                )
                .await;
                // Turn the result into an option.
                // If we get a good result  then return None
                // which will filter this path from future attempts.
                match apply_result {
                    Ok(_) => {
                        debug!("Apply success path = {:?}", &path);
                        None
                    }
                    Err(e) => {
                        info!(
                            "Non ok apply path = {:?} retries = {:?} err = {}",
                            &path, retries, e
                        );
                        Some((path, resource))
                    }
                }
            })
            .collect()
            .await;

        if !unsynced.is_empty() {
            sleep(Duration::from_millis(5000)).await;
        }
    }

    if !unsynced.is_empty() && retries < 0 {
        bail!("Unable to apply resource before running out of retries")
    }

    // We made it this far it's a great success
    Ok(())
}

async fn initial_apply_single(
    kube_client: Client,
    discovery: &Discovery,
    apply_params: &PatchParams,
    overwrite_resources: bool,
    resource: DynamicObject,
) -> Result<()> {
    // Keep the name of this resource.
    let name = resource
        .metadata
        .name
        .clone()
        .context("Everything needs a name")?;

    // Figure out the kubernetes group/kind/version and
    // the endpoints for each in the kubernetes cluster.
    let (api_res, api_cap) = run_discovery(discovery, &resource)?;
    // Build the either namespaced or not kube client api.
    let api = build_api(kube_client, api_res, api_cap, &resource.metadata.namespace)?;

    // Check if the resource already exists.
    // If it does then just skip out.
    if overwrite_resources || api.get_opt(&name).await?.is_none() {
        // Run the patch with apply.
        // However we only care that it applied not the final result right now.
        let _r = api
            .patch(&name, apply_params, &Patch::Apply(resource))
            .await?;
    }

    Ok(())
}

fn run_discovery(
    discovery: &Discovery,
    resource: &DynamicObject,
) -> Result<(ApiResource, ApiCapabilities)> {
    let tm = resource
        .types
        .as_ref()
        .context("Need a type for applying to work")?;
    let gvk = GroupVersionKind::try_from(tm)?;
    discovery
        .resolve_gvk(&gvk)
        .context("Resolving Group Version Kind from resource")
}

fn build_api(
    kube_client: Client,
    api_res: ApiResource,
    api_cap: ApiCapabilities,
    res_namespace: &Option<String>,
) -> Result<Api<DynamicObject>> {
    if api_cap.scope == Scope::Cluster {
        Ok(Api::all_with(kube_client, &api_res))
    } else {
        Ok(Api::namespaced_with(
            kube_client,
            res_namespace
                .as_ref()
                .context("All non-namespaced resources should be in a namespace for bcli")?,
            &api_res,
        ))
    }
}
