use common::kube::CustomResourceExt;
use common::{cluster_spec::BatteryCluster, error::Result};

pub fn run() -> Result<()> {
    print!("{0}", serde_yaml::to_string(&BatteryCluster::crd())?);
    Ok(())
}
