use std::fmt::Debug;

use eyre::{ContextCompat, Result};
use k8s_openapi::{
    api::{
        admissionregistration::v1::MutatingWebhookConfiguration,
        apps::v1::{DaemonSet, Deployment, StatefulSet},
        core::v1::{
            ConfigMap, Namespace, PersistentVolume, PersistentVolumeClaim, Pod, Secret,
            ServiceAccount,
        },
        rbac::v1::{ClusterRole, ClusterRoleBinding, Role, RoleBinding},
        storage::v1::StorageClass,
    },
    apiextensions_apiserver::pkg::apis::apiextensions::v1::CustomResourceDefinition,
    NamespaceResourceScope,
};
use kube_client::{
    api::{DeleteParams, ListParams},
    Api, Client, Resource,
};
use serde::de::DeserializeOwned;

pub async fn delete_all_battery_managed(kube_client: Client) -> Result<()> {
    // We try and remove these resources in an order that should
    // leave kubernetes in a good state.
    delete_all_managed::<MutatingWebhookConfiguration>(kube_client.clone()).await?;

    // Stop all the things that can start new pods
    delete_all_namespaced::<Deployment>(kube_client.clone()).await?;
    delete_all_namespaced::<StatefulSet>(kube_client.clone()).await?;
    delete_all_namespaced::<DaemonSet>(kube_client.clone()).await?;

    // Stop all the pods
    delete_all_namespaced::<Pod>(kube_client.clone()).await?;

    // Remove all the things that can keep data in a namespace
    delete_all_namespaced::<Secret>(kube_client.clone()).await?;
    delete_all_namespaced::<ConfigMap>(kube_client.clone()).await?;
    delete_all_namespaced::<PersistentVolumeClaim>(kube_client.clone()).await?;

    // First delete all the Cluster level RBAC thing that can refer
    // to a service accoun
    delete_all_global::<ClusterRoleBinding>(kube_client.clone()).await?;
    delete_all_global::<ClusterRole>(kube_client.clone()).await?;

    // Now delete the namespace level things
    delete_all_namespaced::<RoleBinding>(kube_client.clone()).await?;
    delete_all_namespaced::<Role>(kube_client.clone()).await?;

    // Service account should be good now.
    delete_all_namespaced::<ServiceAccount>(kube_client.clone()).await?;

    // At this point delete the volumes
    delete_all_global::<PersistentVolume>(kube_client.clone()).await?;
    delete_all_global::<StorageClass>(kube_client.clone()).await?;
    // Since nothing is using these CRDS can go
    delete_all_global::<CustomResourceDefinition>(kube_client.clone()).await?;

    // Nothing should hold the finalizer up now.
    delete_all_global::<Namespace>(kube_client.clone()).await?;
    Ok(())
}

// This is just some
fn list_params() -> ListParams {
    ListParams::default()
        .match_any()
        .labels("battery/managed=true")
}

// For any resource types that support it
// Delete the whole collection in one rpc.
async fn delete_all_managed<K>(kube_client: Client) -> Result<()>
where
    <K as Resource>::DynamicType: Default,
    K: DeserializeOwned + Clone + Debug + Resource,
{
    let api = Api::<K>::all(kube_client.clone());
    let _deleted = api
        .delete_collection(&DeleteParams::foreground(), &list_params())
        .await?;
    Ok(())
}

// For anything that needs a namespace list the resource
// then delete everything.
async fn delete_all_namespaced<K>(kube_client: Client) -> Result<()>
where
    <K as Resource>::DynamicType: Default,
    K: Resource<Scope = NamespaceResourceScope> + DeserializeOwned + Clone + Debug,
{
    let api = Api::<K>::all(kube_client.clone());

    let tagged = api.list(&list_params()).await?;
    for resource in tagged {
        let ns = resource
            .meta()
            .namespace
            .to_owned()
            .context("Should have a namespace")?;
        let name = resource
            .meta()
            .name
            .to_owned()
            .context("Should have a name")?;
        let ns_api: Api<K> = Api::namespaced(kube_client.clone(), &ns);
        ns_api.delete(&name, &DeleteParams::foreground()).await?;
    }
    Ok(())
}

async fn delete_all_global<K: DeserializeOwned + Clone + Debug + Resource>(
    kube_client: Client,
) -> Result<()>
where
    <K as Resource>::DynamicType: Default,
{
    let api = Api::<K>::all(kube_client.clone());

    let tagged = api.list(&list_params()).await?;
    for resource in tagged {
        let name = resource
            .meta()
            .name
            .to_owned()
            .context("Should have a name")?;
        let del_api: Api<K> = Api::all(kube_client.clone());
        del_api.delete(&name, &DeleteParams::foreground()).await?;
    }
    Ok(())
}
