defmodule KubeResources.PrometheusOperator do
  use KubeExt.IncludeResource,
    alertmanagerconfigs_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/alertmanagerconfigs_monitoring_coreos_com.yaml",
    alertmanagers_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/alertmanagers_monitoring_coreos_com.yaml",
    podmonitors_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/podmonitors_monitoring_coreos_com.yaml",
    probes_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/probes_monitoring_coreos_com.yaml",
    prometheuses_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/prometheuses_monitoring_coreos_com.yaml",
    prometheusrules_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/prometheusrules_monitoring_coreos_com.yaml",
    servicemonitors_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/servicemonitors_monitoring_coreos_com.yaml",
    thanosrulers_monitoring_coreos_com:
      "priv/manifests/prometheus_stack/thanosrulers_monitoring_coreos_com.yaml"

  use KubeExt.ResourceGenerator

  import KubeExt.Yaml

  alias KubeResources.MonitoringSettings, as: Settings
  alias KubeExt.Builder, as: B

  @app_name "prometheus-operator"

  resource(:crd_alertmanagerconfigs_monitoring_coreos_com) do
    yaml(get_resource(:alertmanagerconfigs_monitoring_coreos_com))
  end

  resource(:crd_alertmanagers_monitoring_coreos_com) do
    yaml(get_resource(:alertmanagers_monitoring_coreos_com))
  end

  resource(:crd_podmonitors_monitoring_coreos_com) do
    yaml(get_resource(:podmonitors_monitoring_coreos_com))
  end

  resource(:crd_probes_monitoring_coreos_com) do
    yaml(get_resource(:probes_monitoring_coreos_com))
  end

  resource(:crd_prometheuses_monitoring_coreos_com) do
    yaml(get_resource(:prometheuses_monitoring_coreos_com))
  end

  resource(:crd_prometheusrules_monitoring_coreos_com) do
    yaml(get_resource(:prometheusrules_monitoring_coreos_com))
  end

  resource(:crd_servicemonitors_monitoring_coreos_com) do
    yaml(get_resource(:servicemonitors_monitoring_coreos_com))
  end

  resource(:crd_thanosrulers_monitoring_coreos_com) do
    yaml(get_resource(:thanosrulers_monitoring_coreos_com))
  end

  resource(:cluster_role_battery_kube_prometheus_admission) do
    B.build_resource(:cluster_role)
    |> B.name("battery-prometheus-admission")
    |> B.app_labels(@app_name)
    |> B.rules([
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"],
        "verbs" => ["get", "update"]
      }
    ])
  end

  resource(:cluster_role_battery_kube_prometheus_operator) do
    B.build_resource(:cluster_role)
    |> B.name("battery-prometheus-operator")
    |> B.app_labels(@app_name)
    |> B.rules([
      %{
        "apiGroups" => ["monitoring.coreos.com"],
        "resources" => [
          "alertmanagers",
          "alertmanagers/finalizers",
          "alertmanagerconfigs",
          "prometheuses",
          "prometheuses/status",
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
      %{"apiGroups" => ["apps"], "resources" => ["statefulsets"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["configmaps", "secrets"], "verbs" => ["*"]},
      %{"apiGroups" => [""], "resources" => ["pods"], "verbs" => ["list", "delete"]},
      %{
        "apiGroups" => [""],
        "resources" => ["services", "services/finalizers", "endpoints"],
        "verbs" => ["get", "create", "update", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["nodes"], "verbs" => ["list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["namespaces"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      }
    ])
  end

  resource(:cluster_role_binding_battery_kube_prometheus_admission, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-prometheus-admission")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref("battery-prometheus-admission"))
    |> B.subject(B.build_service_account("battery-prometheus-admission", namespace))
  end

  resource(:cluster_role_binding_battery_kube_prometheus_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-prometheus-operator")
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_cluster_role_ref("battery-prometheus-operator"))
    |> B.subject(B.build_service_account("battery-prometheus-operator", namespace))
  end

  resource(:role_admission, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:role)
    |> B.name("battery-prometheus-admission")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.rules([%{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "create"]}])
  end

  resource(:role_binding_admission, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:role_binding)
    |> B.name("battery-prometheus-admission")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.role_ref(B.build_role_ref("battery-prometheus-admission"))
    |> B.subject(B.build_service_account("battery-prometheus-admission", namespace))
  end

  resource(:service_account_admission, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.name("battery-prometheus-admission")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
  end

  resource(:service_account_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_account)
    |> B.name("battery-prometheus-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("prometheus-operator")
  end

  resource(:deployment_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:deployment)
    |> B.name("battery-prometheus-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "replicas" => 1,
      "selector" => %{"matchLabels" => %{"app" => "kube-prometheus-stack-operator"}},
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app" => "kube-prometheus-stack-operator",
            "battery/app" => @app_name,
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "--kubelet-service=kube-system/battery-prometheus-kubelet",
                "--localhost=127.0.0.1",
                "--prometheus-config-reloader=quay.io/prometheus-operator/prometheus-config-reloader:v0.59.1",
                "--config-reloader-cpu-request=200m",
                "--config-reloader-cpu-limit=200m",
                "--config-reloader-memory-request=50Mi",
                "--config-reloader-memory-limit=50Mi",
                "--thanos-default-base-image=quay.io/thanos/thanos:v0.28.0",
                "--web.enable-tls=true",
                "--web.cert-file=/cert/cert",
                "--web.key-file=/cert/key",
                "--web.listen-address=:10250",
                "--web.tls-min-version=VersionTLS13"
              ],
              "image" => "quay.io/prometheus-operator/prometheus-operator:v0.59.1",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "kube-prometheus-stack",
              "ports" => [%{"containerPort" => 10_250, "name" => "https"}],
              "resources" => %{},
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "readOnlyRootFilesystem" => true
              },
              "volumeMounts" => [
                %{"mountPath" => "/cert", "name" => "tls-secret", "readOnly" => true}
              ]
            }
          ],
          "securityContext" => %{
            "fsGroup" => 65_534,
            "runAsGroup" => 65_534,
            "runAsNonRoot" => true,
            "runAsUser" => 65_534
          },
          "serviceAccountName" => "battery-prometheus-operator",
          "volumes" => [
            %{
              "name" => "tls-secret",
              "secret" => %{
                "defaultMode" => 420,
                "secretName" => "battery-prometheus-admission"
              }
            }
          ]
        }
      }
    })
  end

  resource(:job_admission_create, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:job)
    |> B.name("battery-prometheus-admission-create")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.annotation("sidecar.istio.io/inject", "false")
    |> B.spec(%{
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app" => "kube-prometheus-stack-admission-create",
            "sidecar.istio.io/inject" => "false",
            "battery/app" => "prometheus_stack",
            "battery/managed" => "true"
          },
          "name" => "battery-prometheus-admission-create"
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "create",
                "--host=battery-prometheus-operator,battery-prometheus-operator.battery-core.svc",
                "--namespace=battery-core",
                "--secret-name=battery-prometheus-admission"
              ],
              "image" => "k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.3.0",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "create",
              "resources" => %{},
              "securityContext" => %{}
            }
          ],
          "restartPolicy" => "OnFailure",
          "securityContext" => %{
            "runAsGroup" => 2000,
            "runAsNonRoot" => true,
            "runAsUser" => 2000
          },
          "serviceAccountName" => "battery-prometheus-admission"
        }
      }
    })
  end

  resource(:job_admission_patch, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:job)
    |> B.name("battery-prometheus-admission-patch")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.annotation("sidecar.istio.io/inject", "false")
    |> B.spec(%{
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app" => "kube-prometheus-stack-admission-patch",
            "battery/app" => @app_name,
            "sidecar.istio.io/inject" => "false",
            "battery/managed" => "true"
          },
          "name" => "battery-prometheus-admission-patch"
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "patch",
                "--webhook-name=battery-prometheus-admission",
                "--namespace=battery-core",
                "--secret-name=battery-prometheus-admission",
                "--patch-failure-policy=Fail"
              ],
              "image" => "k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.3.0",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "patch",
              "resources" => %{},
              "securityContext" => %{}
            }
          ],
          "restartPolicy" => "OnFailure",
          "securityContext" => %{
            "runAsGroup" => 2000,
            "runAsNonRoot" => true,
            "runAsUser" => 2000
          },
          "serviceAccountName" => "battery-prometheus-admission"
        }
      }
    })
  end

  resource(:mutating_webhook_config_admission, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:mutating_webhook_config)
    |> B.name("battery-prometheus-admission")
    |> B.app_labels(@app_name)
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1", "v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "battery-prometheus-operator",
            "namespace" => namespace,
            "path" => "/admission-prometheusrules/mutate"
          }
        },
        "failurePolicy" => "Ignore",
        "name" => "prometheusrulemutate.monitoring.coreos.com",
        "rules" => [
          %{
            "apiGroups" => ["monitoring.coreos.com"],
            "apiVersions" => ["*"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["prometheusrules"]
          }
        ],
        "sideEffects" => "None",
        "timeoutSeconds" => 10
      }
    ])
  end

  resource(:validating_webhook_config_admission, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:validating_webhook_config)
    |> B.name("battery-prometheus-admission")
    |> B.app_labels(@app_name)
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1", "v1beta1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "battery-prometheus-operator",
            "namespace" => namespace,
            "path" => "/admission-prometheusrules/validate"
          }
        },
        "failurePolicy" => "Ignore",
        "name" => "prometheusrulemutate.monitoring.coreos.com",
        "rules" => [
          %{
            "apiGroups" => ["monitoring.coreos.com"],
            "apiVersions" => ["*"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["prometheusrules"]
          }
        ],
        "sideEffects" => "None"
      }
    ])
  end

  resource(:service_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service)
    |> B.name("battery-prometheus-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "ports" => [%{"name" => "https", "port" => 443, "targetPort" => "https"}],
      "selector" => %{"battery/app" => @app_name},
      "type" => "ClusterIP"
    })
  end

  resource(:service_monitor_operator, battery, _state) do
    namespace = Settings.namespace(battery.config)

    B.build_resource(:service_monitor)
    |> B.name("battery-prometheus-operator")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(%{
      "endpoints" => [
        %{
          "honorLabels" => true,
          "port" => "https",
          "scheme" => "https",
          "tlsConfig" => %{
            "ca" => %{
              "secret" => %{
                "key" => "ca",
                "name" => "battery-prometheus-admission",
                "optional" => false
              }
            },
            "serverName" => "battery-prometheus-operator"
          }
        }
      ],
      "namespaceSelector" => %{"matchNames" => [namespace]},
      "selector" => %{"matchLabels" => %{"battery/app" => @app_name}}
    })
  end
end
