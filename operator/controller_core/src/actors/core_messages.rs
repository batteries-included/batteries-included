use actix::prelude::*;
use common::cluster_spec::BatteryCluster;

#[derive(Clone, Debug)]
pub struct StartMessage;

impl Message for StartMessage {
    type Result = ();
}

#[derive(Clone, Debug)]
pub struct NamespacePresentMessage;

impl Message for NamespacePresentMessage {
    type Result = ();
}

#[derive(Clone, Debug)]
pub struct CrdPresentMessage;

impl Message for CrdPresentMessage {
    type Result = ();
}

// This is the message to listen to that all base
// dependencies are ready. The actual sync and monitor can begin.
#[derive(Clone, Debug)]
pub struct DependenciesReadyMessage;

impl Message for DependenciesReadyMessage {
    type Result = ();
}

#[derive(Clone, Debug)]
pub struct KubeClusterStatusMessage(pub BatteryCluster);
impl Message for KubeClusterStatusMessage {
    type Result = ();
}
