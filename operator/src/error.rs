use std::error::Error;

use kube::Error as KubeError;
use thiserror::Error;
use tracing_subscriber::filter::{FromEnvError, ParseError};

#[derive(Error, Debug)]
pub enum BatteryError {
    #[error("Error during RPC to kube")]
    GeneralKubeClientError {
        #[from]
        source: KubeError,
    },

    #[error("Error while serializing/de-serializing to yaml")]
    SerdeError {
        #[from]
        source: serde_yaml::Error,
    },

    #[error("Error while creating default logger.")]
    EnvLoggingError {
        #[from]
        source: FromEnvError,
    },

    #[error("Error while creating default logger.")]
    ParseLoggingError {
        #[from]
        source: ParseError,
    },

    #[error("Generic boxed error")]
    GenericError {
        #[from]
        source: Box<(dyn Error + Sync + Send + 'static)>,
    },
}
