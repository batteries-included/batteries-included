use std::path::PathBuf;

use eyre::Result;
use tokio::fs;
use tracing::{debug, info};

use crate::spec::InstallationSpec;

pub async fn download_install_spec(url: url::Url) -> Result<InstallationSpec> {
    info!("Getting install spec from {}", &url);
    let result = reqwest::get(url).await?.json::<InstallationSpec>().await?;

    // Re-wrap in Ok so that error's above go to the correct types.
    Ok(result)
}

pub async fn read_install_spec(static_path: PathBuf) -> Result<InstallationSpec> {
    let install_path = static_path.join("public").join("specs").join("dev.json");
    info!("Getting install spec from {}", install_path.display());

    let data = fs::read_to_string(install_path).await?;

    debug!("Got install spec length = {}", data.len());

    Ok(serde_json::from_str(&data)?)
}
