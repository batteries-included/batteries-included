use assert_cmd::Command;
use eyre::{Context, ContextCompat, Result};
use std::{path::PathBuf, time::Duration};
use tempfile::NamedTempFile;
use tracing::{debug, info};

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
    let sleep_duration = Duration::from_secs(5);
    info!(
        "Sleeping {:?} for leader election and port-forward setup",
        sleep_duration
    );
    tokio::time::sleep(sleep_duration).await;
    debug!("Done sleeping, starting to setup db");

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
    tokio::task::spawn_blocking(move || -> Result<()> {
        let out = Command::new("mix")
            .args(command)
            .current_dir(platform_path)
            .output();

        Ok(out?.status.exit_ok()?)
    })
    .await?
}

async fn write_temp_file(install_spec: &InstallationSpec) -> Result<NamedTempFile> {
    let file = NamedTempFile::new()?;

    tokio::fs::write(file.path(), serde_json::to_string_pretty(install_spec)?)
        .await
        .context("Should be able to write the install spec.")?;

    Ok(file)
}
