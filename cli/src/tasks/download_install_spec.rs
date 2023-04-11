use eyre::Result;
use tracing::debug;

use crate::spec::InstallationSpec;

pub async fn get_install_spec(url: url::Url) -> Result<InstallationSpec> {
    debug!("Getting install spec from {}", &url);
    let result = reqwest::get(url).await?.json::<InstallationSpec>().await?;

    // Re-wrap in Ok so that error's above go to the correct types.
    Ok(result)
}
