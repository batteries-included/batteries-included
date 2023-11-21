defmodule CommonCore.Resources.Istio.KialiConfigGenerator do
  @moduledoc false

  import CommonCore.StateSummary.Hosts
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Defaults.Images
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary

  def materialize(_battery, %StateSummary{} = state) do
    namespace_core = core_namespace(state)
    namespace_istio = istio_namespace(state)

    %{
      "auth" => get_auth_config(state, F.sso_installed?(state)),
      "deployment" => %{
        "accessible_namespaces" => ["**"],
        "additional_service_yaml" => %{},
        "affinity" => %{"node" => %{}, "pod" => %{}, "pod_anti" => %{}},
        "configmap_annotations" => %{},
        "custom_secrets" => [],
        "host_aliases" => [],
        "hpa" => %{"api_version" => "autoscaling/v2", "spec" => %{}},
        "image_digest" => "",
        "image_name" => "quay.io/kiali/kiali",
        "image_pull_policy" => "Always",
        "image_pull_secrets" => [],
        "image_version" => Images.kiali_image_version(),
        "ingress" => %{
          "additional_labels" => %{},
          "class_name" => "nginx",
          "override_yaml" => %{"metadata" => %{}}
        },
        "instance_name" => "kiali",
        "logger" => %{
          "log_format" => "text",
          "log_level" => "debug",
          "sampler_rate" => "1",
          "time_field_format" => "2006-01-02T15:04:05Z07:00"
        },
        "namespace" => namespace_istio,
        "node_selector" => %{},
        "pod_annotations" => %{},
        "pod_labels" => %{},
        "priority_class_name" => "",
        "replicas" => 1,
        "resources" => %{
          "limits" => %{"memory" => "1Gi"},
          "requests" => %{"cpu" => "10m", "memory" => "64Mi"}
        },
        "secret_name" => "kiali",
        "security_context" => %{},
        "service_annotations" => %{},
        "service_type" => "",
        "tolerations" => [],
        "version_label" => Images.kiali_image_version(),
        "view_only_mode" => false
      },
      "external_services" => %{
        "custom_dashboards" => %{"enabled" => true},
        "istio" => %{
          "root_namespace" => namespace_istio,
          "component_status" => %{
            "components" => [
              %{"app_label" => "istiod", "is_core" => true, "is_proxy" => false},
              %{
                "app_label" => "istio-ingress",
                "is_core" => true,
                "is_proxy" => true,
                "namespace" => namespace_core
              }
            ]
          }
        },
        "grafana" => %{
          "in_cluster_url" => "http://grafana.#{namespace_core}.svc",
          "url" => grafana_host(state)
        },
        "prometheus" => %{
          "health_check_url" =>
            "http://vmselect-main-cluster.#{namespace_core}.svc:8481/select/0/prometheus/api/v1/status/tsdb",
          "url" => "http://vmselect-main-cluster.#{namespace_core}.svc:8481/select/0/prometheus/"
        },
        "tracing" => %{
          "enabled" => false
        }
      },
      "identity" => %{"cert_file" => "", "private_key_file" => ""},
      "istio_namespace" => namespace_istio,
      "kiali_feature_flags" => %{
        "certificates_information_indicators" => %{
          "enabled" => true,
          "secrets" => ["cacerts", "istio-ca-secret"]
        },
        "clustering" => %{
          "autodetect_secrets" => %{
            "enabled" => true,
            "label" => "kiali.io/multiCluster=true"
          },
          "clusters" => []
        },
        "disabled_features" => [],
        "validations" => %{"ignore" => ["KIA1301"]}
      },
      "login_token" => %{"signing_key" => "gEmf58MPasrZkPsh"},
      "server" => %{
        "metrics_enabled" => true,
        "metrics_port" => 9090,
        "port" => 20_001,
        "web_port" => 80,
        "web_root" => "/kiali"
      }
    }
  end

  defp get_auth_config(state, true = _is) do
    case CommonCore.StateSummary.KeycloakSummary.client(state.keycloak_state, "kiali") do
      %{realm: realm, client: %{clientId: client_id, secret: client_secret}} ->
        keycloak_url = "http://#{keycloak_host(state)}/realms/#{realm}"

        %{
          "strategy" => "openid",
          "openid" => %{
            "client_id" => client_id,
            "client_secret" => client_secret,
            "disable_rbac" => true,
            "issuer_uri" => keycloak_url
          }
        }

      _ ->
        # If there is no client yet, still set the strategy so that it's secure
        %{
          "openid" => %{},
          "strategy" => "openid"
        }
    end
  end

  defp get_auth_config(_state, false = _is) do
    %{
      "openid" => %{},
      "openshift" => %{"client_id_prefix" => "kiali"},
      "strategy" => "anonymous"
    }
  end
end
