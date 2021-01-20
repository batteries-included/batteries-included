use tracing_subscriber::EnvFilter;

use crate::error::BatteryError;

pub fn try_init_logging() -> Result<(), BatteryError> {
    let filter = EnvFilter::try_from_default_env().or_else(|_| EnvFilter::try_new("info"))?;

    // TODO(elliott): Make this take some args for local development. I assume json won't be that readable
    Ok(tracing_subscriber::fmt()
        .with_env_filter(filter)
        .json()
        .try_init()?)
}
