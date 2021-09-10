use common::{
    cluster_spec::BatteryCluster,
    error::Result,
    namespace::default_namespace,
    permissions::{cluster_binding, service_account},
};
use kube::CustomResourceExt;

pub fn run() -> Result<()> {
    print!("{0}", serde_yaml::to_string(&default_namespace())?);
    // println!("---");
    print!("{0}", serde_yaml::to_string(&BatteryCluster::crd())?);
    // println!("---");
    print!("{0}", serde_yaml::to_string(&service_account())?);
    // println!("---");
    print!("{0}", serde_yaml::to_string(&cluster_binding())?);
    Ok(())
}
