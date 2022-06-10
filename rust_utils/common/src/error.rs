use std::error::Error;

use kube::config::InferConfigError;
use kube::Error as KubeError;
use reqwest::Error as ReqwestError;
use thiserror::Error;
use tokio::task::JoinError;
use tracing_subscriber::filter::{FromEnvError, ParseError};

#[derive(Error, Debug)]
pub enum BatteryError {
    #[error("Kubernetes config error")]
    KubeConfigError(#[from] InferConfigError),

    #[error("Error during RPC to kube")]
    GeneralKubeClient(#[from] KubeError),

    #[error("Error while serializing/de-serializing to json")]
    SerdeJson(#[from] serde_json::Error),

    #[error("Error while serializing/de-serializing to yaml")]
    SerdeYaml(#[from] serde_yaml::Error),

    #[error("Error while creating default logger.")]
    EnvLogging(#[from] FromEnvError),

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
