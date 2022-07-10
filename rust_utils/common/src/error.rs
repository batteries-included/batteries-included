use std::error::Error;

#[cfg(feature = "kube")]
use crate::kube::config::InferConfigError;
#[cfg(feature = "kube")]
use crate::kube::Error as KubeError;
use reqwest::Error as ReqwestError;
use thiserror::Error;
use tokio::task::JoinError;
#[cfg(feature = "tracing-subscriber")]
use tracing_subscriber::filter::{FromEnvError, ParseError};

#[derive(Error, Debug)]
pub enum BatteryError {
    #[error("Operation timed out")]
    Timeout,

    #[cfg(feature = "kube")]
    #[error("Kubernetes config error")]
    KubeConfigError(#[from] InferConfigError),

    #[cfg(feature = "kube")]
    #[error("Error during RPC to kube")]
    GeneralKubeClient(#[from] KubeError),

    #[error("Error while serializing/de-serializing to json")]
    SerdeJson(#[from] serde_json::Error),

    #[error("Error while serializing/de-serializing to yaml")]
    SerdeYaml(#[from] serde_yaml::Error),

    #[cfg(feature = "tracing-subscriber")]
    #[error("Error while creating default logger.")]
    EnvLogging(#[from] FromEnvError),

    #[cfg(feature = "tracing-subscriber")]
    #[error("Error while creating default logger.")]
    ParseLogging(#[from] ParseError),

    #[error("Generic boxed error")]
    Generic(#[from] Box<(dyn Error + Sync + Send + 'static)>),

    #[error("Reqwest http error.")]
    Reqwest(#[from] ReqwestError),

    #[error("I/O error")]
    IO(#[from] std::io::Error),

    #[error("Tokio join error")]
    JoinError(#[from] JoinError),

    #[error("Error unwrapping None")]
    UnexpectedNone,
}

pub type Result<T, E = BatteryError> = std::result::Result<T, E>;
