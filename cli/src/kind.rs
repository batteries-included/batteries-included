use eyre::Result;
use std::{
    path::Path,
    process::{Command, Output},
};
use tracing::{debug, info};

pub fn get_kubeconfig(kind_path: &Path, cluster_name: &str) -> Result<Output> {
    Ok(Command::new(kind_path)
        .args(["get", "kubeconfig", "-n", cluster_name])
        .output()?)
}

pub fn start_cluster(kind_path: &Path, cluster_name: &str) -> Result<()> {
    info!("Starting Kind Cluster, {}", cluster_name);
    let res = Command::new(kind_path)
        .args(["-v2", "create", "cluster", "-n", cluster_name])
        .output()?;

    Ok(res.status.exit_ok()?)
}

pub fn stop_cluster(kind_path: &Path, cluster_name: &str) -> Result<()> {
    info!("Stopping/Removing kind cluster {}", cluster_name);

    let res = Command::new(kind_path)
        .args(["-v2", "delete", "cluster", "-n", cluster_name])
        .output()?;

    Ok(res.status.exit_ok()?)
}

pub fn ensure_cluster_started(kind_path: &Path, cluster_name: &str) -> Result<()> {
    if get_kubeconfig(kind_path, cluster_name)?.status.success() {
        debug!("Got kubeconfig for {} assuming it is alive", cluster_name);
        // We assume that the cluster is running if
        // kind sees it and returns it to us.
        Ok(())
    } else {
        // The cluster isn't there. So
        if start_cluster(kind_path, cluster_name).is_err() {
            let _res = stop_cluster(kind_path, cluster_name);
            start_cluster(kind_path, cluster_name)
        } else {
            Ok(())
        }
    }
}
