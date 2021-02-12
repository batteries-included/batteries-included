use std::collections::BTreeMap;

use common::{cluster_spec::DEFAULT_NAMESPACE, error::Result};
use k8s_openapi::api::{
    apps::v1::Deployment,
    core::v1::{ConfigMap, Service},
};
use serde_json::json;

use kube::{
    api::{Patch, PatchParams},
    client::Client as KubeClient,
    Api,
};

pub struct PrometheusInstaller {
    pub base_labels: BTreeMap<String, String>,
    deployment_name: String,
    service_name: String,
    config_map_name: String,
}

impl Default for PrometheusInstaller {
    fn default() -> Self {
        Self::new()
    }
}

impl PrometheusInstaller {
    #[must_use]
    pub fn new() -> Self {
        let base_labels: BTreeMap<String, String> = vec![
            ("purpose".to_string(), "general".to_string()),
            ("app".to_string(), "prometheus".to_string()),
        ]
        .into_iter()
        .collect();
        let deployment_name = "prometheus-deployment".to_string();
        let service_name = "prometheus-service".to_string();
        let config_map_name = "prometheus-config".to_string();
        Self {
            base_labels,
            deployment_name,
            service_name,
            config_map_name,
        }
    }

    pub async fn sync(&self, kube_client: KubeClient, running: bool) -> Result<()> {
        let deployments: Api<Deployment> = Api::namespaced(kube_client.clone(), DEFAULT_NAMESPACE);
        let config_maps: Api<ConfigMap> = Api::namespaced(kube_client.clone(), DEFAULT_NAMESPACE);
        let services: Api<Service> = Api::namespaced(kube_client, DEFAULT_NAMESPACE);

        if running {
            let params = PatchParams::apply("battery_operator");
            let dep_patch = Patch::Apply(self.build_prometheus_deployment(2)?);
            deployments
                .patch(&self.deployment_name, &params, &dep_patch)
                .await?;

            let cfg_patch = Patch::Apply(self.build_prometheus_configmap()?);
            config_maps
                .patch(&self.config_map_name, &params, &cfg_patch)
                .await?;

            let svc_patch = Patch::Apply(self.build_prometheus_service()?);
            services
                .patch(&self.service_name, &params, &svc_patch)
                .await?;
        }

        Ok(())
    }
    pub fn build_prometheus_deployment(&self, replicas: i32) -> Result<Deployment> {
        Ok(serde_json::from_value(json!({
            "metadata":{
                "name": self.deployment_name,
                "labels": self.base_labels
            },
            "spec": {
                "replicas": replicas,
                "selector": {
                    "matchLabels": self.base_labels,
                },
                "template": {
                    "metadata":{
                        "name":self.deployment_name,
                        "labels": self.base_labels
                    },
                    "spec":{
                        "containers": [{
                            "name": "prometheus",
                            "image": "prom/prometheus",
                            "volumeMounts": [{
                                "name":"config-volume",
                                "mountPath":"/etc/prometheus",
                            }],
                            "ports": [{"containerPort": 9090, "name": "default-port"}]
                        }],
                        "volumes": [{
                            "name":"config-volume",
                            "configMap": {
                                "name": self.config_map_name,
                                "optional": true,
                            }
                        }]
                    }
                }
            }
        }))?)
    }

    pub fn build_prometheus_configmap(&self) -> Result<ConfigMap> {
        let yml_conents = "rule_files:
        - '/etc/prometheus-rules/*.rules'";
        Ok(serde_json::from_value(json!({
            "metadata": {
                "name": self.config_map_name,
                "labels": self.base_labels.clone()
            },
            "data": {
                "prometheus.yml":yml_conents,
            }
        }))?)
    }

    pub fn build_prometheus_service(&self) -> Result<Service> {
        Ok(serde_json::from_value(json!({
            "metadata":{
                "name":self.service_name,
                "labels": self.base_labels,
            },
            "spec": {
                "selector": self.base_labels,
                "ports":[{
                    "port": 9090,
                    "targetPort": 9090,
                    "protocol": "TCP"
                }],
            },
        }))?)
    }
}

#[cfg(test)]
mod test_prometheus {
    use super::*;

    #[test]
    fn test_build_service() {
        let pi = PrometheusInstaller::new();
        let res = pi.build_prometheus_service();
        assert_eq!(true, res.is_ok());
    }

    #[test]
    fn test_build_deployment() {
        let pi = PrometheusInstaller::new();
        let res = pi.build_prometheus_deployment(3);
        assert_eq!(true, res.is_ok());
    }
}
