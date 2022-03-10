use k8s_openapi::api::rbac::v1::{ClusterRoleBinding, RoleRef, Subject};
use kube::api::{ObjectMeta, Patch, PatchParams};
use kube::{Api, Client};
use serde_json::json;
use tracing::debug;

use crate::error::Result;
use crate::labels::default_labels;
use crate::namespace::DEFAULT_NAMESPACE;
use k8s_openapi::api::core::v1::ServiceAccount;

pub const SERVICE_ACCOUNT_NAME: &str = "battery-admin";
pub const CLUSTER_ROLE_BINDING_NAME: &str = "battery-admin-cluster-admin";

pub fn service_account() -> ServiceAccount {
    ServiceAccount {
        metadata: ObjectMeta {
            name: Some(SERVICE_ACCOUNT_NAME.to_owned()),
            namespace: Some(DEFAULT_NAMESPACE.to_owned()),
            labels: Some(default_labels("batteries-included")),
            ..ObjectMeta::default()
        },
        ..ServiceAccount::default()
    }
}

pub fn cluster_binding() -> ClusterRoleBinding {
    ClusterRoleBinding {
        metadata: ObjectMeta {
            name: Some(CLUSTER_ROLE_BINDING_NAME.to_string()),
            labels: Some(default_labels("batteries-included")),
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
            namespace: Some(DEFAULT_NAMESPACE.to_owned()),
            ..Subject::default()
        }]),
    }
}

pub async fn is_service_account_installed(client: Client) -> bool {
    let sa: Api<ServiceAccount> = Api::namespaced(client, DEFAULT_NAMESPACE);
    debug!("Trying to get service account");
    let res = sa.get(SERVICE_ACCOUNT_NAME).await;
    res.is_ok()
}

pub async fn is_cluster_role_binding_installed(client: Client) -> bool {
    let cluster_roles: Api<ClusterRoleBinding> = Api::all(client);
    debug!("Trying to get cluster role binding");
    let res = cluster_roles.get(CLUSTER_ROLE_BINDING_NAME).await;
    res.is_ok()
}
pub async fn ensure_service_account(client: Client) -> Result<()> {
    if is_service_account_installed(client.clone()).await {
        Ok(())
    } else {
        let sa: Api<ServiceAccount> = Api::namespaced(client, DEFAULT_NAMESPACE);
        let params = PatchParams::apply("battery_operator").force();
        let patch = Patch::Apply(json!(&service_account()));
        Ok(sa
            .patch(SERVICE_ACCOUNT_NAME, &params, &patch)
            .await
            .map(|_| ())?)
    }
}

pub async fn ensure_admin(client: Client) -> Result<()> {
    if is_cluster_role_binding_installed(client.clone()).await {
        Ok(())
    } else {
        let sa: Api<ClusterRoleBinding> = Api::all(client);
        let params = PatchParams::apply("battery_operator").force();
        let patch = Patch::Apply(json!(&cluster_binding()));
        Ok(sa
            .patch(CLUSTER_ROLE_BINDING_NAME, &params, &patch)
            .await
            .map(|_| ())?)
    }
}
