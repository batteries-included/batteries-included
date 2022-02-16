defmodule KubeResources.PrometheusOperator do
  @moduledoc """
  This module is responsible for getting the prometheues operator all set up and running.

  This can generate a config and will also add on alerting/monitoring.
  """
  import KubeExt.Yaml

  alias KubeResources.MonitoringSettings

  @prometheus_crd_path "priv/manifests/prometheus/prometheus-operator-0prometheusCustomResourceDefinition.yaml"
  @prometheus_rule_crd_path "priv/manifests/prometheus/prometheus-operator-0prometheusruleCustomResourceDefinition.yaml"

  @probe_crd_path "priv/manifests/prometheus/prometheus-operator-0probeCustomResourceDefinition.yaml"
  @service_mon_crd_path "priv/manifests/prometheus/prometheus-operator-0servicemonitorCustomResourceDefinition.yaml"
  @pod_mon_crd_path "priv/manifests/prometheus/prometheus-operator-0podmonitorCustomResourceDefinition.yaml"

  @am_config_crd_path "priv/manifests/prometheus/prometheus-operator-0alertmanagerConfigCustomResourceDefinition.yaml"
  @am_crd_path "priv/manifests/prometheus/prometheus-operator-0alertmanagerCustomResourceDefinition.yaml"

  @thanos_rule_crd_path "priv/manifests/prometheus/prometheus-operator-0thanosrulerCustomResourceDefinition.yaml"

  @port 8443
  @internal_port 8080

  @internal_port_name "http-internal"
  @port_name "https"

  def materialize(config) do
    %{
      # Then the CRDS since they are needed for cluster roles.
      "/1/setup/prometheus_crd" => yaml(prometheus_crd_content()),
      "/1/setup/prometheus_rule_crd" => yaml(prometheus_rule_crd_content()),
      "/1/setup/service_monitor_crd" => yaml(service_mon_crd_content()),
      "/1/setup/podmonitor_crd" => yaml(pod_mon_crd_content()),
      "/1/setup/probe_crd" => yaml(probe_crd_content()),
      "/1/setup/am_config_crd" => yaml(am_config_crd_content()),
      "/1/setup/am_crd" => yaml(am_crd_content()),
      "/1/setup/thanos_ruler_crd" => yaml(thanos_rule_crd_content()),
      # for the prometheus operator account stuff
      "/2/setup/operator_service_account" => service_account(config),
      "/2/setup/operator_cluster_role" => cluster_role(config),
      # Bind them
      "/3/setup/operator_cluster_role_binding" => cluster_role_binding(config),
      # Run Something.
      "/3/setup/operator_deployment" => deployment(config),
      # Make it available.
      "/3/setup/operator_service" => service(config)
    }
  end

  def service_account(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-prometheus-operator",
        "namespace" => namespace
      }
    }
  end

  def cluster_role(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        },
        "name" => "battery-prometheus-operator"
      },
      "rules" => [
        %{
          "apiGroups" => ["monitoring.coreos.com"],
          "resources" => [
            "alertmanagers",
            "alertmanagers/finalizers",
            "alertmanagerconfigs",
            "prometheuses",
            "prometheuses/finalizers",
            "thanosrulers",
            "thanosrulers/finalizers",
            "servicemonitors",
            "podmonitors",
            "probes",
            "prometheusrules"
          ],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => ["apps"],
          "resources" => ["statefulsets"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps", "secrets"],
          "verbs" => ["*"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["pods"],
          "verbs" => ["list", "delete"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["services", "services/finalizers", "endpoints"],
          "verbs" => ["get", "create", "update", "delete"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["nodes"],
          "verbs" => ["list", "watch"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["namespaces"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["networking.k8s.io"],
          "resources" => ["ingresses"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["authentication.k8s.io"],
          "resources" => ["tokenreviews"],
          "verbs" => ["create"]
        },
        %{
          "apiGroups" => ["authorization.k8s.io"],
          "resources" => ["subjectaccessreviews"],
          "verbs" => ["create"]
        }
      ]
    }
  end

  def cluster_role_binding(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        },
        "name" => "battery-prometheus-operator"
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-prometheus-operator"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-prometheus-operator",
          "namespace" => namespace
        }
      ]
    }
  end

  def deployment(config) do
    namespace = MonitoringSettings.namespace(config)
    image = MonitoringSettings.prometheus_operator_image(config)
    version = MonitoringSettings.prometheus_operator_version(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        },
        "namespace" => namespace,
        "name" => "battery-prometheus-operator"
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "prometheus-operator"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "prometheus-operator",
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--kubelet-service=kube-system/kubelet",
                  "--prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:#{version}"
                ],
                "image" => "#{image}:#{version}",
                "name" => "prometheus-operator",
                "ports" => [
                  %{"containerPort" => @internal_port, "name" => @internal_port_name}
                ],
                "resources" => %{
                  "limits" => %{"cpu" => "200m", "memory" => "200Mi"},
                  "requests" => %{"cpu" => "100m", "memory" => "100Mi"}
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false
                }
              },
              KubeResources.RBAC.proxy_container(
                "http://127.0.0.1:#{@internal_port}/",
                @port,
                @port_name
              )
            ],
            "nodeSelector" => %{
              "kubernetes.io/os": "linux"
            },
            "securityContext" => %{
              "runAsNonRoot" => true,
              "runAsUser" => 65_534
            },
            "serviceAccountName" => "battery-prometheus-operator"
          }
        }
      }
    }
  end

  def service(config) do
    namespace = MonitoringSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "prometheus-operator",
          "battery/managed" => "True"
        },
        "name" => "prometheus-operator",
        "namespace" => namespace
      },
      "spec" => %{
        "clusterIP" => "None",
        "ports" => [
          %{
            "name" => @port_name,
            "port" => @port,
            "targetPort" => @port_name
          }
        ],
        "selector" => %{
          "battery/app" => "prometheus-operator"
        }
      }
    }
  end

  def monitors(config) do
    namespace = MonitoringSettings.namespace(config)

    [
      %{
        "apiVersion" => "monitoring.coreos.com/v1",
        "kind" => "ServiceMonitor",
        "metadata" => %{
          "labels" => %{
            "battery/app" => "prometheus-operator",
            "battery/managed" => "True"
          },
          "name" => "prometheus-operator",
          "namespace" => namespace
        },
        "spec" => %{
          "endpoints" => [
            %{
              "bearerTokenFile" => "/var/run/secrets/kubernetes.io/serviceaccount/token",
              "honorLabels" => true,
              "port" => @port_name,
              "scheme" => "https",
              "tlsConfig" => %{"insecureSkipVerify" => true}
            }
          ],
          "selector" => %{
            "matchLabels" => %{
              "battery/app" => "prometheus-operator"
            }
          }
        }
      }
    ]
  end

  defp prometheus_crd_content, do: unquote(File.read!(@prometheus_crd_path))
  defp prometheus_rule_crd_content, do: unquote(File.read!(@prometheus_rule_crd_path))

  defp probe_crd_content, do: unquote(File.read!(@probe_crd_path))
  defp service_mon_crd_content, do: unquote(File.read!(@service_mon_crd_path))
  defp pod_mon_crd_content, do: unquote(File.read!(@pod_mon_crd_path))

  defp am_crd_content, do: unquote(File.read!(@am_crd_path))
  defp am_config_crd_content, do: unquote(File.read!(@am_config_crd_path))

  defp thanos_rule_crd_content, do: unquote(File.read!(@thanos_rule_crd_path))
end
