use eyre::Result;
use std::{path::Path, process::Command};

pub fn list_clusters(kind_path: &Path) -> Result<Vec<String>> {
    // Run the kind command
    // Gathering the
    let command_output = Command::new(kind_path).args(["get", "clusters"]).output()?;

    let output_string = String::from_utf8(command_output.stdout)?;
    let result = output_string.split('\n').map(|s| s.to_string()).collect();
    Ok(result)
}

pub fn start_cluster(kind_path: &Path, cluster_name: &str) -> Result<()> {
    let command_status = Command::new(kind_path)
        .args(["create", "cluster", "-n", cluster_name])
        .status()?;

    Ok(command_status.exit_ok()?)
}

pub fn stop_cluster(kind_path: &Path, cluster_name: &str) -> Result<()> {
    let command_status = Command::new(kind_path)
        .args(["delete", "cluster", "-n", cluster_name])
        .status()?;

    Ok(command_status.exit_ok()?)
}

pub fn ensure_cluster_started(kind_path: &Path, cluster_name: &str) -> Result<()> {
    let running_clusters = list_clusters(kind_path)?;
    if running_clusters.iter().any(|run| run == cluster_name) {
        // We assume that the cluster is running if
        // kind sees it and returns it to us.
        Ok(())
    } else {
        // The cluster isn't there. So
        start_cluster(kind_path, cluster_name)
    }
}
