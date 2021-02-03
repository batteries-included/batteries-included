use std::collections::BTreeMap;

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
    pub fn build_prometheus_deployment(&self, replicas: i32) -> Deployment {
        Deployment {
            metadata: ObjectMeta {
                name: Some("prometheus-deployment".to_string()),
                labels: Some(self.prometheus_labels.clone()),
                ..ObjectMeta::default()
            },
            spec: Some(DeploymentSpec {
                replicas: Some(replicas),
                selector: LabelSelector {
                    match_labels: Some(self.prometheus_labels.clone()),
                    ..LabelSelector::default()
                },
                template: PodTemplateSpec {
                    metadata: Some(ObjectMeta {
                        labels: Some(self.prometheus_labels.clone()),
                        ..ObjectMeta::default()
                    }),
                    spec: Some(PodSpec {
                        containers: vec![Container {
                            image: Some("prom/prometheus".to_string()),
                            volume_mounts: Some(vec![VolumeMount {
                                name: "config-volume".to_string(),
                                mount_path: "/etc/prometheus/prometheus.yml".to_string(),
                                sub_path: Some("prometheus.yml".to_string()),
                                ..VolumeMount::default()
                            }]),
                            ports: Some(vec![ContainerPort {
                                container_port: 9090,
                                ..ContainerPort::default()
                            }]),
                            ..Container::default()
                        }],
                        volumes: Some(vec![Volume {
                            name: "config-volume".to_string(),
                            ..Volume::default()
                        }]),
                        ..PodSpec::default()
                    }),
                },
                ..DeploymentSpec::default()
            }),
            ..Deployment::default()
        }
    }

    pub fn build_prometheus_service(&self) -> Service {
        Service {
            metadata: ObjectMeta {
                name: Some("prometheus".to_string()),
                ..ObjectMeta::default()
            },
            spec: Some(ServiceSpec {
                selector: Some(self.prometheus_labels.clone()),
                ports: Some(vec![ServicePort {
                    name: Some("main".to_string()),
                    port: 9090,
                    target_port: Some(IntOrString::Int(9090)),
                    ..ServicePort::default()
                }]),
                ..ServiceSpec::default()
            }),
            ..Service::default()
        }
    }
}
