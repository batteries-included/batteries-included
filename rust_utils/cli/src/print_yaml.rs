use common::{cluster_spec::BatteryCluster, error::Result};
use kube::CustomResourceExt;

pub fn run() -> Result<()> {
    print!("{0}", serde_yaml::to_string(&BatteryCluster::crd())?);
    Ok(())
}
