use std::collections::HashSet;
use std::fs::OpenOptions;
use std::path::PathBuf;

use super::dev::ForwardSpec;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use tracing::instrument;
use tracing_error::TracedError;

#[derive(Debug, Error)]
pub enum Error {
    #[error("Could not locate config dir")]
    BadEnv,
    #[error("Could not open config file {0}")]
    Open(PathBuf, #[source] std::io::Error),
    #[error("Could not write config file {0}")]
    Write(PathBuf, #[source] serde_yaml::Error),
    #[error("Could not read config file {0}")]
    Read(PathBuf, #[source] serde_yaml::Error),
}

/// CLI configuration options
#[derive(Default, Debug, Serialize, Deserialize)]
pub struct Config {
    pub port_forwards: HashSet<ForwardSpec>,
}

impl Config {
    pub fn path() -> Result<PathBuf, TracedError<Error>> {
        let mut config_path = dirs::config_dir().ok_or(Error::BadEnv)?;
        config_path.extend(["batteries", "cli.yaml"]);
        Ok(config_path)
    }

    #[instrument]
    pub fn load() -> Result<Self, TracedError<Error>> {
        let path = &Self::path()?;
        let f = OpenOptions::new()
            .read(true)
            .open(&path)
            .map_err(|e| Error::Open(path.clone(), e))?;

        Ok(serde_yaml::from_reader(f).map_err(|e| Error::Read(path.clone(), e))?)
    }

    pub fn save(&self) -> Result<(), TracedError<Error>> {
        let path = &Self::path()?;
        let f = OpenOptions::new()
            .write(true)
            .create(true)
            .open(&path)
            .map_err(|e| Error::Open(path.clone(), e))?;

        Ok(serde_yaml::to_writer(f, self).map_err(|e| Error::Write(path.clone(), e))?)
    }
}
