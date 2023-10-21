use std::path::PathBuf;

use eyre::Result;
use futures::stream::FuturesUnordered;
use futures::stream::StreamExt;
use tracing::info;
use url::Url;

use crate::args::BaseArgs;
use crate::postgres_kube::wait_healthy_pg;
use crate::spec::InstallationSpec;
use crate::tasks::ensure_podman_started;
use crate::tasks::{
    add_local_to_spec, download_install_spec, ensure_kube_provider_started, initial_apply,
    port_forward_postgres, port_forward_spec, read_install_spec, setup_platform_db,
};

#[allow(clippy::too_many_arguments)]
pub async fn dev_command(
    base_args: BaseArgs,
    start_podman: bool,
    installation_url: Url,
    overwrite_resources: bool,
    forward_postgres: bool,
    forward_pods: Vec<String>,
    platform_dir: Option<PathBuf>,
    static_dir: Option<PathBuf>,
) -> Result<()> {
    // If this is OSX we make sure that podman is setup.
    if start_podman && base_args.os == "macos" {
        ensure_podman_started(base_args.temp_dir.clone()).await?;
    }

    // Get the install spec from http server
    let install_spec = get_install_spec(static_dir, installation_url).await?;

    // Now that we have the install spec and know what type of
    // kubernetes cluster we're expecting, make sure that it's started.
    // This will download the needed binaries
    ensure_kube_provider_started(
        base_args.dir_parent.as_path(),
        &base_args.arch,
        &install_spec,
    )
    .await?;

    let spec_with_local = add_local_to_spec(install_spec).await?;

    // Create a new kubernetes client.
    let kube_client = (base_args.kube_client_factory)();

    // Apply the initial resources. This will `Apply` the resources that
    // don't currently exist.  If the resource exists but is different
    // the resource will be left alone, unless overwrite_resources is true.
    initial_apply(
        kube_client.clone(),
        overwrite_resources,
        spec_with_local.initial_resources.clone(),
    )
    .await?;

    // Wait for the postgres pod to be healthy. There's no reason to try continuing
    // until postgres is up and running.
    wait_healthy_pg(kube_client.clone(), "battery-base").await?;

    port_forward_and_setup(
        kube_client,
        platform_dir,
        spec_with_local,
        forward_postgres,
        forward_pods,
    )
    .await
}

async fn get_install_spec(
    static_dir_opt: Option<PathBuf>,
    installation_url: Url,
) -> Result<InstallationSpec> {
    // If we know where to find the static files, we'll use them. Otherwise
    // download them from the installation url.
    if let Some(static_path) = static_dir_opt {
        info!("Using local static files: {}", static_path.display());
        // Using the local files allows long lived branches to change the install
        // spec.
        read_install_spec(static_path).await
    } else {
        info!("Downloading static files from {}", installation_url);
        // Act like production and download from the interwebs.
        download_install_spec(installation_url).await
    }
}

async fn port_forward_and_setup(
    kube_client: kube_client::Client,
    platform_dir: Option<PathBuf>,
    install_spec: InstallationSpec,

    forward_postgres: bool,
    forward_pods: Vec<String>,
) -> Result<()> {
    // For this we are going to add each of the tasks that need to run
    // in this collection. Then we'll poll `next` to get the next complete
    // future.
    //
    // In this way we can run many things in parallel. Some that complete
    // others that don't. Any tasks that complete successfully are done
    // Anything that's an error causes a total bail out.
    let mut unordered = FuturesUnordered::new();

    if forward_postgres {
        // Start the task that will follow the master of pg run a portforward.
        let pg_kube_client = kube_client.clone();
        let postgres_handle: tokio::task::JoinHandle<Result<()>> =
            tokio::spawn(async { port_forward_postgres(pg_kube_client, "battery-base").await });
        unordered.push(postgres_handle);

        // If there's a platform dir then add the setup task
        if let Some(dir) = platform_dir {
            let setup_handle: tokio::task::JoinHandle<Result<()>> =
                tokio::spawn(async move { setup_platform_db(dir, &install_spec).await });
            unordered.push(setup_handle);
        }
    }

    // Add each of the specific pod port forwards that need to run.
    unordered.extend(forward_pods.into_iter().map(|spec_string| {
        let c = kube_client.clone();

        let h: tokio::task::JoinHandle<Result<()>> =
            tokio::spawn(async move { port_forward_spec(c, spec_string).await });

        h
    }));

    // Take until every task is complete.
    // This should never exit if there are port forwards.
    while let Some(res) = unordered.next().await {
        match res {
            Ok(_marker) => info!("Completed dev task successfully"),
            e => return e?,
        }
    }

    Ok(())
}
