use std::error::Error;

use kube::Error as KubeError;
use reqwest::Error as ReqwestError;
use thiserror::Error;
use tracing_subscriber::filter::{FromEnvError, ParseError};

#[derive(Error, Debug)]
pub enum BatteryError {
    #[error("Error during RPC to kube")]
    GeneralKubeClient {
        #[from]
        source: KubeError,
    },

    #[error("Error while serializing/de-serializing to yaml")]
    Serde {
        #[from]
        source: serde_yaml::Error,
    },

    #[error("Error while serializing/de-serializing to json")]
    SerdeJSON {
        #[from]
        source: serde_json::Error,
    },

    #[error("Error while creating default logger.")]
    EnvLogging {
        #[from]
        source: FromEnvError,
    },

    #[error("Error while creating default logger.")]
    ParseLogging {
        #[from]
        source: ParseError,
    },

    #[error("Generic boxed error")]
    Generic {
        #[from]
        source: Box<(dyn Error + Sync + Send + 'static)>,
    },

    #[error("Reqwest http error.")]
    Reqwest {
        #[from]
        source: ReqwestError,
    },

    #[error("Bad control server registration.")]
    BadRegistration,
}

pub type Result<T> = std::result::Result<T, BatteryError>;
