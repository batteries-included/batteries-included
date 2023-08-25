use eyre::Result;

use crate::{args::BaseArgs, tasks::delete_all_battery_managed};

pub async fn uninstall_command(base_args: BaseArgs) -> Result<()> {
    // Create a new kubernetes client.
    let kube_client = (base_args.kube_client_factory)();

    delete_all_battery_managed(kube_client).await
}
