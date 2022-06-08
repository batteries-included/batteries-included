use k8s_openapi::api::core::v1::{Namespace, ServiceAccount};
use k8s_openapi::api::rbac::v1::{ClusterRoleBinding, RoleRef, Subject};
use kube::api::ObjectMeta;
use kube::Resource;
use std::collections::BTreeMap;

pub const ACCOUNT_NAME: &str = "test-account";
pub const APP_NAME: &str = "batteries-included";
pub const CLUSTER_NAME: &str = "default-cluster";
pub const CLUSTER_ROLE_BINDING_NAME: &str = "battery-admin-cluster-admin";
pub const CRD_NAME: &str = "batteryclusters.batteriesincl.com";
pub const NAMESPACE: &str = "battery-core";
pub const SERVICE_ACCOUNT_NAME: &str = "battery-admin";

pub fn default_namespace() -> Namespace {
    let mut ns = Namespace::default();
    ns.meta_mut().name = Some(NAMESPACE.to_string());
    ns.apply_default_labels("batteries_included");
    if let Some(labels) = ns.meta_mut().labels.as_mut() {
        labels.insert("istio-injection".to_string(), "enabled".to_string());
    }
    ns
}

pub trait BatteryDefaults {
    /// Helper to apply the default labels for a Batteries Included cluster
    fn apply_default_labels(&mut self, app_name: &str);
}

impl<T> BatteryDefaults for T
where
    T: Resource,
{
    fn apply_default_labels(&mut self, app_name: &str) {
        let meta = self.meta_mut();
        if meta.labels.is_none() {
            meta.labels = Some(BTreeMap::new())
        }
        if let Some(map) = meta.labels.as_mut() {
            map.extend([
                ("battery/app".to_owned(), app_name.to_owned()),
                ("battery/managed".to_owned(), "true".to_owned()),
            ]);
        }
    }
}

/// Return the "default" `Namespace` for a Batteries Included cluster
pub fn namespace() -> Namespace {
    Namespace {
        metadata: ObjectMeta {
            name: Some(NAMESPACE.to_string()),
            namespace: None,
            ..Default::default()
        },
        ..Default::default()
    }
}

/// Return the "default" `ServiceAccount` for a Batteries Included cluster
pub fn service_account() -> ServiceAccount {
    let mut sa = ServiceAccount {
        metadata: ObjectMeta {
            name: Some(SERVICE_ACCOUNT_NAME.to_owned()),
            namespace: Some(NAMESPACE.to_owned()),
            ..ObjectMeta::default()
        },
        ..Default::default()
    };
    sa.apply_default_labels(APP_NAME);
    sa
}

/// Return the "default" `ClusterRoleBinding` for a Batteries Included cluster
pub fn cluster_binding() -> ClusterRoleBinding {
    let mut crb = ClusterRoleBinding {
        metadata: ObjectMeta {
            name: Some(CLUSTER_ROLE_BINDING_NAME.to_string()),
            ..ObjectMeta::default()
        },
        role_ref: RoleRef {
            api_group: "rbac.authorization.k8s.io".to_owned(),
            kind: "ClusterRole".to_owned(),
            name: "cluster-admin".to_owned(),
        },
        subjects: Some(vec![Subject {
            kind: "ServiceAccount".to_owned(),
            name: SERVICE_ACCOUNT_NAME.to_owned(),
            namespace: Some(NAMESPACE.to_owned()),
            ..Subject::default()
        }]),
    };
    crb.apply_default_labels(APP_NAME);
    crb
}
