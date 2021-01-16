use kube::Error as KubeError;
use thiserror::Error;

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
}
