use std::collections::BTreeMap;

use common::error::Result;
use k8s_openapi::api::{apps::v1::Deployment, core::v1::Service};
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
                            "name": "prometheus",
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
                            "configMap": {
                                "name": "prometheus-cm",
                                "optional": true,
                            }
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
