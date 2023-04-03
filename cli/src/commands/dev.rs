use eyre::Result;
use url::Url;

use crate::args::BaseArgs;
use crate::kube_provider::ensure_kube_provider_started;
use crate::spec::get_install_spec;
use crate::{initial_apply, port_forward};

pub async fn dev_command(
    base_args: BaseArgs,
    installation_url: Url,
    overwrite_resources: bool,
) -> Result<()> {
    let install_spec = get_install_spec(installation_url).await?;
    ensure_kube_provider_started(
        base_args.dir_parent.as_path(),
        &base_args.arch,
        &install_spec,
    )
    .await?;

    let kube_client = (base_args.kube_client_factory)();
    initial_apply(
        kube_client.clone(),
        overwrite_resources,
        install_spec.initial_resource,
    )
    .await?;

    port_forward(kube_client, "battery-base").await?;

    Ok(())
}
