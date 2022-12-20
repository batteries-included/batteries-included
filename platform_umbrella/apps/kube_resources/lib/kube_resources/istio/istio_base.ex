defmodule KubeResources.IstioBase do
  use KubeExt.IncludeResource,
    authorizationpolicies_security_istio_io:
      "priv/manifests/istio_base/authorizationpolicies_security_istio_io.yaml",
    destinationrules_networking_istio_io:
      "priv/manifests/istio_base/destinationrules_networking_istio_io.yaml",
    envoyfilters_networking_istio_io:
      "priv/manifests/istio_base/envoyfilters_networking_istio_io.yaml",
    gateways_networking_istio_io: "priv/manifests/istio_base/gateways_networking_istio_io.yaml",
    istiooperators_install_istio_io:
      "priv/manifests/istio_base/istiooperators_install_istio_io.yaml",
    peerauthentications_security_istio_io:
      "priv/manifests/istio_base/peerauthentications_security_istio_io.yaml",
    proxyconfigs_networking_istio_io:
      "priv/manifests/istio_base/proxyconfigs_networking_istio_io.yaml",
    requestauthentications_security_istio_io:
      "priv/manifests/istio_base/requestauthentications_security_istio_io.yaml",
    serviceentries_networking_istio_io:
      "priv/manifests/istio_base/serviceentries_networking_istio_io.yaml",
    sidecars_networking_istio_io: "priv/manifests/istio_base/sidecars_networking_istio_io.yaml",
    telemetries_telemetry_istio_io:
      "priv/manifests/istio_base/telemetries_telemetry_istio_io.yaml",
    virtualservices_networking_istio_io:
      "priv/manifests/istio_base/virtualservices_networking_istio_io.yaml",
    wasmplugins_extensions_istio_io:
      "priv/manifests/istio_base/wasmplugins_extensions_istio_io.yaml",
    workloadentries_networking_istio_io:
      "priv/manifests/istio_base/workloadentries_networking_istio_io.yaml",
    workloadgroups_networking_istio_io:
      "priv/manifests/istio_base/workloadgroups_networking_istio_io.yaml"

  use KubeExt.ResourceGenerator

  import KubeExt.Yaml
  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  @app_name "istio_base"

  resource(:istio_namespace, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name(namespace)
  end

  resource(:cluster_role_binding_istio_reader_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("istio-reader-battery-istio")
    |> B.app_labels(@app_name)
    |> B.component_label("istio-reader")
    |> B.role_ref(B.build_cluster_role_ref("istio-reader-battery-istio"))
    |> B.subject(B.build_service_account("istio-reader-service-account", namespace))
  end

  resource(:cluster_role_binding_istiod_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("istiod-battery-istio")
    |> B.app_labels(@app_name)
    |> B.component_label("istiod")
    |> B.role_ref(B.build_cluster_role_ref("istiod-battery-istio"))
    |> B.subject(B.build_service_account("istiod-service-account", namespace))
  end

  resource(:cluster_role_istio_reader_battery_istio) do
    B.build_resource(:cluster_role)
    |> B.name("istio-reader-battery-istio")
    |> B.app_labels(@app_name)
    |> B.component_label("istio-reader")
    |> B.rules([
      %{
        "apiGroups" => [
          "config.istio.io",
          "security.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => [
          "endpoints",
          "pods",
          "services",
          "nodes",
          "replicationcontrollers",
          "namespaces",
          "secrets"
        ],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["apps"],
        "resources" => ["replicasets"],
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
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceexports"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceimports"],
        "verbs" => ["get", "watch", "list"]
      }
    ])
  end

  resource(:cluster_role_istiod_battery_istio) do
    B.build_resource(:cluster_role)
    |> B.name("istiod-battery-istio")
    |> B.app_labels(@app_name)
    |> B.component_label("istiod")
    |> B.rules([
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["mutatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => [
          "config.istio.io",
          "security.istio.io",
          "networking.istio.io",
          "authentication.istio.io",
          "rbac.istio.io",
          "telemetry.istio.io"
        ],
        "resources" => ["*"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["workloadentries/status"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["pods", "nodes", "services", "namespaces", "endpoints"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["discovery.k8s.io"],
        "resources" => ["endpointslices"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses", "ingressclasses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses/status"],
        "verbs" => ["*"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["configmaps"],
        "verbs" => ["create", "get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resources" => [
          "certificatesigningrequests",
          "certificatesigningrequests/approval",
          "certificatesigningrequests/status"
        ],
        "verbs" => ["update", "create", "get", "delete", "watch"]
      },
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resourceNames" => ["kubernetes.io/legacy-unknown"],
        "resources" => ["signers"],
        "verbs" => ["approve"]
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
      },
      %{
        "apiGroups" => ["networking.x-k8s.io", "gateway.networking.k8s.io"],
        "resources" => ["*"],
        "verbs" => ["get", "watch", "list"]
      },
      %{
        "apiGroups" => ["networking.x-k8s.io", "gateway.networking.k8s.io"],
        "resources" => ["*"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["gatewayclasses"],
        "verbs" => ["create", "update", "patch", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "watch", "list"]},
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceexports"],
        "verbs" => ["get", "watch", "list", "create", "delete"]
      },
      %{
        "apiGroups" => ["multicluster.x-k8s.io"],
        "resources" => ["serviceimports"],
        "verbs" => ["get", "watch", "list"]
      }
    ])
  end

  resource(:crd_authorizationpolicies_security_istio_io) do
    yaml(get_resource(:authorizationpolicies_security_istio_io))
  end

  resource(:crd_destinationrules_networking_istio_io) do
    yaml(get_resource(:destinationrules_networking_istio_io))
  end

  resource(:crd_envoyfilters_networking_istio_io) do
    yaml(get_resource(:envoyfilters_networking_istio_io))
  end

  resource(:crd_gateways_networking_istio_io) do
    yaml(get_resource(:gateways_networking_istio_io))
  end

  resource(:crd_istiooperators_install_istio_io) do
    yaml(get_resource(:istiooperators_install_istio_io))
  end

  resource(:crd_peerauthentications_security_istio_io) do
    yaml(get_resource(:peerauthentications_security_istio_io))
  end

  resource(:crd_proxyconfigs_networking_istio_io) do
    yaml(get_resource(:proxyconfigs_networking_istio_io))
  end

  resource(:crd_requestauthentications_security_istio_io) do
    yaml(get_resource(:requestauthentications_security_istio_io))
  end

  resource(:crd_serviceentries_networking_istio_io) do
    yaml(get_resource(:serviceentries_networking_istio_io))
  end

  resource(:crd_sidecars_networking_istio_io) do
    yaml(get_resource(:sidecars_networking_istio_io))
  end

  resource(:crd_telemetries_telemetry_istio_io) do
    yaml(get_resource(:telemetries_telemetry_istio_io))
  end

  resource(:crd_virtualservices_networking_istio_io) do
    yaml(get_resource(:virtualservices_networking_istio_io))
  end

  resource(:crd_wasmplugins_extensions_istio_io) do
    yaml(get_resource(:wasmplugins_extensions_istio_io))
  end

  resource(:crd_workloadentries_networking_istio_io) do
    yaml(get_resource(:workloadentries_networking_istio_io))
  end

  resource(:crd_workloadgroups_networking_istio_io) do
    yaml(get_resource(:workloadgroups_networking_istio_io))
  end

  resource(:role_binding_istiod_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("istiod-battery-istio")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("istiod")
    |> B.role_ref(B.build_role_ref("istiod-battery-istio"))
    |> B.subject(B.build_service_account("istiod-service-account", namespace))
  end

  resource(:role_istiod_battery_istio, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:role)
    |> B.name("istiod-battery-istio")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("istiod")
    |> B.rules([
      %{
        "apiGroups" => ["networking.istio.io"],
        "resources" => ["gateways"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["create", "get", "watch", "list", "update", "delete"]
      }
    ])
  end

  resource(:service_account_istio_reader, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:service_account)
    |> B.name("istio-reader-service-account")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("istio-reader")
  end

  resource(:service_account_istiod, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:service_account)
    |> B.name("istiod-service-account")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("istiod")
  end

  resource(:validating_webhook_config_istiod_default_validator, _battery, state) do
    namespace = istio_namespace(state)

    B.build_resource(:validating_webhook_config)
    |> B.name("istiod-default-validator")
    |> B.app_labels(@app_name)
    |> B.component_label("istiod")
    |> B.label("istio", "istiod")
    |> B.label("istio.io/rev", "default")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1beta1", "v1"],
        "clientConfig" => %{
          "service" => %{"name" => "istiod", "namespace" => namespace, "path" => "/validate"}
        },
        "failurePolicy" => "Ignore",
        "name" => "validation.istio.io",
        "rules" => [
          %{
            "apiGroups" => ["security.istio.io", "networking.istio.io"],
            "apiVersions" => ["*"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["*"]
          }
        ],
        "sideEffects" => "None"
      }
    ])
  end
end
