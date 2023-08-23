use eyre::Result;

use crate::{args::BaseArgs, tasks::stop_kind_cluster};

pub async fn stop_command(base_args: BaseArgs) -> Result<()> {
    // For now we always stop the kind cluster.
    // Later on this will have to figure out what is there from a cached local install spec
    stop_kind_cluster(base_args.dir_parent.as_path(), &base_args.arch).await
}
