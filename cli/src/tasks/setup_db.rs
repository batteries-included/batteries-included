use assert_cmd::Command;
use eyre::Result;
use std::path::PathBuf;
use tracing::debug;

pub async fn setup_platform_db(platform_path: PathBuf) -> Result<()> {
    run_mix_command(platform_path.clone(), vec!["deps.get".to_string()]).await?;
    run_mix_command(
        platform_path.clone(),
        vec!["compile".to_string(), "--force".to_string()],
    )
    .await?;
    run_mix_command(platform_path, vec!["setup".to_string()]).await?;

    Ok(())
}

async fn run_mix_command(platform_path: PathBuf, command: Vec<String>) -> Result<()> {
    debug!("Running mix command {:?}", command);
    tokio::task::spawn_blocking(move || -> Result<()> {
        let out = Command::new("mix")
            .args(command)
            .current_dir(platform_path)
            .output();

        Ok(out?.status.exit_ok()?)
    })
    .await?
}
