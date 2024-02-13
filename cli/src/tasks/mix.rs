use std::{path::PathBuf, time::Duration};

use eyre::{bail, Context, Result};
use tokio::process::Command;
use tracing::{info, warn};

const MAX_DELAY: Duration = Duration::from_secs(30);

pub async fn run_mix_command(platform_path: PathBuf, command: Vec<String>) -> Result<()> {
    let mut retries = 20;
    let mut delay = Duration::from_millis(500);
    while retries > 0 {
        let res = run_mix_command_with_retry(platform_path.clone(), command.clone()).await;
        if res.is_ok() {
            return res;
        }
        warn!("failed mix command sleeping retries = {}", retries);
        tokio::time::sleep(delay).await;
        delay = (2 * delay).min(MAX_DELAY);
        retries -= 1;
    }
    bail!("Failed to run mix command")
}

pub async fn run_mix_command_with_retry(
    platform_path: PathBuf,
    command: Vec<String>,
) -> Result<()> {
    info!("Running mix command {:?}", command);
    // We really have no way of knowing if postgres has been
    // set up with the correct users and permissions to create
    // tables and connect, other than to give it a try.
    let out = Command::new("mix")
        .args(command)
        .current_dir(platform_path)
        .output()
        .await
        .context("Failed to start mix command")?;

    info!("mix command status = {}", out.status.clone());
    Ok(out.status.exit_ok()?)
}
