use std::path::PathBuf;

use eyre::Result;
use futures::join;
use std::time::Duration;
use tracing::{debug, info};
use url::Url;

use crate::args::BaseArgs;
use crate::postgres_kube::wait_healthy_pg;
use crate::spec::get_install_spec;
use crate::tasks::{ensure_kube_provider_started, initial_apply, port_forward, setup_platform_db};

pub async fn dev_command(
    base_args: BaseArgs,
    installation_url: Url,
    overwrite_resources: bool,
    forward_postgres: bool,
    platform_dir: Option<PathBuf>,
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

    wait_healthy_pg(kube_client.clone(), "battery-base").await?;

    if forward_postgres {
        let pf = tokio::task::spawn(async move {
            let _ = port_forward(kube_client, "battery-base").await;
        });

        if platform_dir.is_some() {
            let task = tokio::task::spawn(async move {
                let sleep_duration = Duration::from_secs(5);
                info!(
                    "Sleeping {:?} for leader election and port-forward setup",
                    sleep_duration
                );
                tokio::time::sleep(sleep_duration).await;
                debug!("Done sleeping, starting to setup db");

                let res = setup_platform_db(platform_dir.unwrap()).await;

                info!("Completed setup of db platform, {:?}", res);
            });
            let _ = join!(pf, task);
            Ok(())
        } else {
            Ok(pf.await?)
        }
    } else {
        Ok(())
    }
}
