use std::path::Path;

use crate::install_bin::install_kind;
use crate::kind::ensure_cluster_started;
use crate::spec::{InstallationSpec, ProviderType};
use eyre::Result;

const DEFAULT_CLUSTER_NAME: &str = "batteries";

pub async fn ensure_kube_provider_started(
    dir_parent: &Path,
    arch: &str,
    install_spec: &InstallationSpec,
) -> Result<()> {
    if install_spec.kube_cluster.provider == ProviderType::Kind {
        let kind_path = install_kind(dir_parent, arch).await?;
        ensure_cluster_started(kind_path.as_path(), DEFAULT_CLUSTER_NAME)
    } else {
        Ok(())
    }
}
