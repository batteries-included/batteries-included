use std::{path::PathBuf, time::Duration};

use eyre::{bail, Context, Result};
use tokio::process::Command;
use tracing::{info, warn};

const MAX_DELAY: Duration = Duration::from_secs(30);

pub async fn run_mix_command(platform_path: PathBuf, command: Vec<String>) -> Result<()> {
    info!("Running mix command {:?}", command);

    let task = async move || -> Result<()> {
        let out = Command::new("mix")
            .args(command)
            .current_dir(platform_path)
            .output()
            .await?;

        info!("mix command status = {}", out.status.clone());
        Ok(out.status.exit_ok()?)
    };
    let mut retries = 20;
    let mut delay = Duration::from_millis(500);
    // We really have no way of knowing if postgres has been
    // set up with the correct users and permissions to create
    // tables and connect, other than to give it a try.
    while retries > 0 {
        let spawn_res = tokio::task::spawn_blocking(task.clone()).await;
        let res = spawn_res.context("Failed to spawn mix command")?.await;
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
