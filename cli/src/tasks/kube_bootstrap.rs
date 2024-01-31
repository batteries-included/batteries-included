use std::path::PathBuf;

use crate::spec::InstallationSpec;
use eyre::{ContextCompat, Result};

use super::{get_install_spec::write_temp_file, mix::run_mix_command};

pub async fn mix_bootstrap_kube(
    platform_path: PathBuf,
    install_spec: &InstallationSpec,
) -> Result<()> {
    let temp_file = write_temp_file(install_spec).await?;

    let path_string = temp_file
        .path()
        .as_os_str()
        .to_str()
        .context("Should have a temp file path")?;

    let bootstrap_args = vec!["do", "deps.get,", "compile,", "kube.bootstrap", path_string]
        .into_iter()
        .map(&String::from)
        .collect();

    run_mix_command(platform_path.clone(), bootstrap_args).await?;
    Ok(())
}
