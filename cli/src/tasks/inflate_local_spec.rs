use crate::{
    docker::get_kind_ip_address_pools,
    spec::{InstallationSpec, ProviderType},
};

use eyre::Result;

pub async fn add_local_to_spec(install_spec: InstallationSpec) -> Result<InstallationSpec> {
    let mut spec = install_spec;

    if spec.kube_cluster.provider == ProviderType::Kind {
        let mut kind_ips = get_kind_ip_address_pools().await?;
        spec.target_summary.ip_address_pools.append(&mut kind_ips);
    }

    Ok(spec)
}
