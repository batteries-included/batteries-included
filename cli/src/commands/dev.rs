use std::path::PathBuf;

use eyre::Result;
use futures::join;
use url::Url;

use crate::args::BaseArgs;
use crate::postgres_kube::wait_healthy_pg;
use crate::spec::InstallationSpec;
use crate::tasks::{
    ensure_kube_provider_started, get_install_spec, initial_apply, port_forward, setup_platform_db,
};

pub async fn dev_command(
    base_args: BaseArgs,
    installation_url: Url,
    overwrite_resources: bool,
    forward_postgres: bool,
    platform_dir: Option<PathBuf>,
) -> Result<()> {
    // Get the install spec from http server
    let install_spec = get_install_spec(installation_url).await?;
    // Now that we have the install spec and know what type of
    // kubernetes cluster we're expecting, make sure that it's started.
    // This will download the needed binaries
    ensure_kube_provider_started(
        base_args.dir_parent.as_path(),
        &base_args.arch,
        &install_spec,
    )
    .await?;

    // Create a new kubernetes client.
    let kube_client = (base_args.kube_client_factory)();

    // Apply the initial resources. This will `Apply` the resources that
    // don't currently exist.  If the resource exists but is different
    // the resource will be left alone, unless overwrite_resources is true.
    initial_apply(
        kube_client.clone(),
        overwrite_resources,
        install_spec.initial_resources.clone(),
    )
    .await?;

    // Wait for the postgres pod to be healthy. There's no reason to try continuing
    // until postgres is up and running.
    wait_healthy_pg(kube_client.clone(), "battery-base").await?;

    match (forward_postgres, platform_dir) {
        (true, Some(dir)) => port_forward_and_setup(kube_client, dir, install_spec).await,
        (true, None) => port_forward(kube_client, "battery-base").await,
        (_, _) => Ok(()),
    }
}

async fn port_forward_and_setup(
    kube_client: kube_client::Client,
    platform_dir: PathBuf,
    install_spec: InstallationSpec,
) -> Result<()> {
    let pf = port_forward(kube_client, "battery-base");
    let setup = setup_platform_db(platform_dir, &install_spec);
    let (pf_res, _task_res) = join!(pf, setup);
    pf_res
}
