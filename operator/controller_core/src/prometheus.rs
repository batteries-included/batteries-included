use std::collections::BTreeMap;

use common::error::Result;
use k8s_openapi::{
    api::{
        apps::v1::{Deployment, DeploymentSpec},
        core::v1::{
            Container, ContainerPort, PodSpec, PodTemplateSpec, Service, ServicePort, ServiceSpec,
            Volume, VolumeMount,
        },
    },
    apimachinery::pkg::{apis::meta::v1::LabelSelector, util::intstr::IntOrString},
};
use kube::api::ObjectMeta;
use serde_json::json;

pub struct PrometheusInstaller {
    pub base_labels: BTreeMap<String, String>,
    prometheus_labels: BTreeMap<String, String>,
}

impl Default for PrometheusInstaller {
    fn default() -> Self {
        Self::new()
    }
}

impl PrometheusInstaller {
    #[must_use]
    pub fn new() -> Self {
        let base_labels: BTreeMap<String, String> =
            vec![("purpose".to_string(), "general-prometheus".to_string())]
                .into_iter()
                .collect();
        let mut prometheus_labels = base_labels.clone();
        prometheus_labels.extend(vec![("app".to_string(), "prometheus".to_string())].into_iter());
        Self {
            base_labels,
            prometheus_labels,
        }
    }
    pub fn build_prometheus_deployment(&self, replicas: i32) -> Result<Deployment> {
        Ok(serde_json::from_value(json!({
            "metadata":{
                "name":"prometheus-deployment",
                "labels": self.prometheus_labels.clone()
            },
            "spec": {
                "replicas": replicas,
                "selector": {
                    "matchLabels": self.prometheus_labels.clone(),
                },
                "template": {
                    "metadata":{
                        "name":"prometheus-deployment",
                        "labels": self.prometheus_labels.clone()
                    },
                    "spec":{
                        "containers": [{
                            "image": "prom/prometheus",
                            "volumeMounts": [{
                                "name":"config-volume",
                                "mountPath":"/etc/prometheus/prometheus.yml",
                                "subPath":"prometheus.yml"
                            }],
                            "ports": [{"containerPort": 9090}]
                        }],
                        "volumes": [{
                            "name":"config-volume",
                            "configMap": "prometheus-cm"
                        }]
                    }
                }
            }
        }))?)
    }

    pub fn build_prometheus_service(&self) -> Result<Service> {
        Ok(serde_json::from_value(json!({
            "metadata":{
                "name":"prometheus",
                "labels": self.prometheus_labels.clone()
            },
            "spec": {
                "selector": self.prometheus_labels.clone()
            },
            "ports":[{
                "name": 9090,
                "targetPort": 9090,
                "protocol": "TCP"
            }]
        }))?)
    }
}
