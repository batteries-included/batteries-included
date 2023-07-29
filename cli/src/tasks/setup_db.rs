use assert_cmd::Command;
use eyre::{Context, ContextCompat, Result};
use std::{path::PathBuf, time::Duration};
use tempfile::NamedTempFile;
use tracing::{info, warn};

use crate::spec::InstallationSpec;

pub async fn setup_platform_db(
    platform_path: PathBuf,
    install_spec: &InstallationSpec,
) -> Result<()> {
    let temp_file = write_temp_file(install_spec).await?;
    info!(
        "Wrote temp file with installation spec to {}",
        temp_file.path().display()
    );

    run_mix_command(platform_path.clone(), vec!["deps.get".to_string()]).await?;
    run_mix_command(platform_path.clone(), vec!["compile".to_string()]).await?;
    run_mix_command(platform_path.clone(), vec!["setup".to_string()]).await?;

    let path_string = temp_file
        .path()
        .as_os_str()
        .to_str()
        .context("Should have a temp file path")?
        .to_owned();
    let seed_args = vec!["seed.control".to_string(), path_string];
    run_mix_command(platform_path, seed_args).await?;

    info!("Setup complete. Database ready.");

    Ok(())
}

async fn run_mix_command(platform_path: PathBuf, command: Vec<String>) -> Result<()> {
    info!("Running mix command {:?}", command);

    let task = move || -> Result<()> {
        let out = Command::new("mix")
            .args(command)
            .current_dir(platform_path)
            .output()?;

        info!("mix command status = {}", out.status.clone());
        Ok(out.status.exit_ok()?)
    };
    let mut retries = 15;
    // We really have no way of knowing if postgres has been
    // set up with the correct users and permissions to create
    // tables and connect, other than to give it a try.
    while retries > 0 {
        let res = tokio::task::spawn_blocking(task.clone()).await?;
        if res.is_ok() {
            return res;
        }
        warn!("failed mix command sleeping, retries = {}", retries);
        tokio::time::sleep(Duration::from_millis(950)).await;
        retries -= 1;
    }
    tokio::task::spawn_blocking(task).await?
}

async fn write_temp_file(install_spec: &InstallationSpec) -> Result<NamedTempFile> {
    let file = NamedTempFile::new()?;

    tokio::fs::write(file.path(), serde_json::to_string_pretty(install_spec)?)
        .await
        .context("Should be able to write the install spec.")?;

    Ok(file)
}
