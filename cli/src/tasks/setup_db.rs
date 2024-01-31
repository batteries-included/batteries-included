use eyre::{ContextCompat, Result};
use std::path::PathBuf;
use tracing::info;

use crate::{
    spec::InstallationSpec,
    tasks::{get_install_spec::write_temp_file, mix::run_mix_command},
};

pub async fn setup_platform_db(
    platform_path: PathBuf,
    install_spec: &InstallationSpec,
) -> Result<()> {
    let temp_file = write_temp_file(install_spec).await?;
    info!(
        "Wrote temp file with installation spec to {}",
        temp_file.path().display()
    );

    run_mix_command(platform_path.clone(), vec!["setup".to_string()]).await?;

    let path_string = temp_file
        .path()
        .as_os_str()
        .to_str()
        .context("Should have a temp file path")?;

    let seed_args = vec!["seed.control", path_string]
        .into_iter()
        .map(&String::from)
        .collect();

    run_mix_command(platform_path, seed_args).await?;

    println!("Setup complete. Database ready.");

    Ok(())
}
