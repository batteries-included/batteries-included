use crate::{
    docker::get_kind_ip_address_pools,
    spec::{InstallationSpec, ProviderType},
};

use eyre::Result;
use tracing::warn;

pub async fn add_local_to_spec(install_spec: InstallationSpec) -> Result<InstallationSpec> {
    let mut spec = install_spec;

    if spec.kube_cluster.provider == ProviderType::Kind {
        match get_kind_ip_address_pools().await {
            // If we found some ips that can be load balancers
            // Then add them to the target summary
            Ok(kind_ips) => spec.target_summary.ip_address_pools.extend(kind_ips),
            // Don't error out if there's some issue.
            // That will mean that ip address pools don't
            // get created, but everything else should
            // continue.
            Err(e) => warn!("Error getting ip kind ip address pools. report = {}", e),
        }
    }
    Ok(spec)
}
