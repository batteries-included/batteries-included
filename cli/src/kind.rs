use eyre::Result;
use std::{
    path::Path,
    process::{Command, Output},
};
use tracing::{debug, info, warn};

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

pub fn check_kube_status(kind_path: &Path, cluster_name: &str) -> bool {
    if let Ok(res) = get_kubeconfig(kind_path, cluster_name)
        && res.status.success()
    {
        true
    } else {
        warn!("Failed to get kube status");
        false
    }
}

pub fn ensure_cluster_started(kind_path: &Path, cluster_name: &str) -> Result<()> {
    if check_kube_status(kind_path, cluster_name) {
        debug!("Got kubeconfig for {} assuming it is alive", cluster_name);
        // We assume that the cluster is running if
        // kind sees it and returns it to us.
        Ok(())
    } else {
        // Sometimes kind leaves behind just enough for kubectl to see things
        // and for kind to, but not enough for them to work.
        // Check for that case by...
        //
        // Fucking turning it off and back on again.
        //
        // While yes I admit that I tell people this is the best advice
        // for dealing with sporadic issues, as starting from a known good state
        // is likely to yield success.
        //
        // I have become Microsoft IT help desk.
        // Rather than a bored IT help desk asking if you have tried power cycling your
        // PC, now I write rust to power cycle emulated VM running in
        // container kubernetes clusters.
        //
        // OoOoOo technology is great.
        if start_cluster(kind_path, cluster_name).is_err() {
            let _res = stop_cluster(kind_path, cluster_name);
            start_cluster(kind_path, cluster_name)
        } else {
            Ok(())
        }
    }
}
