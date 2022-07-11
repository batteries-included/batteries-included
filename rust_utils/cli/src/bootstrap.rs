use std::convert::TryFrom;
use std::time::Duration;

use color_eyre::{eyre::eyre, eyre::WrapErr, Result};
use common::kube::api::{ApiResource, DynamicObject, GroupVersionKind, Patch, PatchParams};
use common::kube::discovery::{oneshot, ApiCapabilities, Scope};
use common::kube::{Api, Client, ResourceExt};
use futures::stream::FuturesUnordered;
use futures::TryStreamExt;

use tokio::time;
use tracing::{debug, info, instrument, trace, warn, Instrument};

#[derive(rust_embed::RustEmbed)]
#[folder = "$CARGO_MANIFEST_DIR/../../bootstrap/"]
#[include = "*.yaml"]
struct Configs;

// https://github.com/kube-rs/kube-rs/blob/9f1df5e7c0b1fc92d3f7d883445c25bffd245375/examples/kubectl.rs#L237
#[instrument("deserializing", skip(data))]
pub fn multidoc_deserialize(data: &[u8]) -> Result<Vec<DynamicObject>> {
    use serde::Deserialize;
    let mut docs = vec![];
    for de in serde_yaml::Deserializer::from_slice(data) {
        docs.push(DynamicObject::deserialize(de)?);
    }
    trace!("found {} docs", docs.len());
    Ok(docs)
}

// https://github.com/kube-rs/kube-rs/blob/9f1df5e7c0b1fc92d3f7d883445c25bffd245375/examples/kubectl.rs#L210
fn dynamic_api(
    ar: &ApiResource,
    caps: &ApiCapabilities,
    client: &Client,
    ns: &Option<String>,
) -> Api<DynamicObject> {
    let client = client.clone();
    if caps.scope == Scope::Cluster {
        Api::all_with(client, ar)
    } else if let Some(namespace) = ns {
        Api::namespaced_with(client, namespace, ar)
    } else {
        Api::default_namespaced_with(client, ar)
    }
}

#[instrument(skip_all)]
async fn api_for_object(client: &Client, obj: &DynamicObject) -> Result<Api<DynamicObject>> {
    let tm = obj
        .types
        .as_ref()
        .ok_or_else(|| eyre!("{} has no types", &obj.name()))?;
    let gvk = GroupVersionKind::try_from(tm)?;
    let (ar, caps) = oneshot::pinned_kind(client, &gvk)
        .in_current_span()
        .await
        .wrap_err_with(|| eyre!("failed to resolve gvk: {:?}", gvk))?;
    Ok(dynamic_api(&ar, &caps, client, &obj.namespace()))
}

#[instrument(skip(client, obj), fields(name = &obj.name().as_str()))]
async fn apply_doc(path: &str, client: &Client, obj: &DynamicObject) -> Result<()> {
    let api = api_for_object(client, obj).in_current_span().await?;
    debug!("sending patch");
    let mut wait = Duration::from_millis(50);
    let pp = PatchParams::apply("battery-bootstrap").force();
    while let Err(e) = api
        .patch(&obj.name(), &pp, &Patch::Apply(&obj))
        .in_current_span()
        .await
    {
        warn!(?wait, ?e, "failed to apply patch");
        time::sleep(wait).await;
        wait += wait;
    }
    info!("applied patch");
    Ok(())
}

#[instrument("bootstrap")]
pub async fn run() -> Result<()> {
    let client = Client::try_default().in_current_span().await?;
    let parsed_objs = Configs::iter()
        .map(|path| (Configs::get(&path).unwrap(), path))
        .filter_map(|(file, path)| {
            multidoc_deserialize(&file.data)
                .ok()
                .map(|docs| (path, docs))
        })
        .flat_map(|(path, docs)| docs.into_iter().map(move |doc| (path.clone(), doc)));

    let futs = parsed_objs
        .into_iter()
        .map(|(path, obj)| {
            let client = &client;
            let duration = Duration::from_secs(5);
            let do_apply = async move { apply_doc(&path, client, &obj).in_current_span().await };
            time::timeout(duration, do_apply).in_current_span()
        })
        .collect::<FuturesUnordered<_>>();

    info!("will apply {} objects", futs.len());
    futs.try_collect::<Vec<_>>().await?;

    Ok(())
}
