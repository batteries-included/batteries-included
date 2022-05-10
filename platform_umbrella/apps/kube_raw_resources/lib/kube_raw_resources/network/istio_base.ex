defmodule KubeRawResources.IstioBase do
  @moduledoc false

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeRawResources.NetworkSettings

  @reader_app "istio-reader"
  @istiod_app "istiod"

  @crd_path "priv/manifests/istio/base.crd.yaml"

  def materialize(config) do
    %{
      "/namespace" => namespace(config),
      "/crd" => crd(config),
      "/istiod/service_account" => service_account_istiod(config),
      "/istiod/cluster_role" => cluster_role_istiod(config),
      "/istiod/cluster_role_binding" => cluster_role_binding_istiod(config),
      "/istiod/gateway/cluster_role" => cluster_role_istiod_gateway(config),
      "/istiod/gateway/cluster_role_binding" => cluster_role_binding_istiod_gateway(config),
      "/istiod/role" => role_istiod(config),
      "/istiod/role_binding" => role_binding_istiod(config),
      "/reader/service_account" => service_account_reader(config),
      "/reader/cluster_role" => cluster_role_reader(config),
      "/reader/cluster_role_binding" => cluster_role_binding_reader(config),
      "/validating_webhook_configuration" => validating_webhook_configuration(config)
    }
  end

  def crd(_), do: yaml(crd_content())

  defp namespace(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:namespace)
    |> B.name(namespace)
    |> B.app_labels(@istiod_app)
  end

  def service_account_reader(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:service_account)
    |> B.name("istio-reader-service-account")
    |> B.namespace(namespace)
    |> B.app_labels(@reader_app)
  end

  def service_account_istiod(config) do
    namespace = NetworkSettings.istio_namespace(config)

    B.build_resource(:service_account)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.app_labels(@istiod_app)
  end

  def cluster_role_istiod(config) do
    rules = [
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
          "telemetry.istio.io",
          "extensions.istio.io"
        ],
        "verbs" => ["get", "watch", "list"],
        "resources" => ["*"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"],
        "resources" => ["workloadentries"]
      },
      %{
        "apiGroups" => ["networking.istio.io"],
        "verbs" => ["get", "watch", "list", "update", "patch", "create", "delete"],
        "resources" => ["workloadentries/status"]
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
        "resources" => ["signers"],
        "resourceNames" => ["kubernetes.io/legacy-unknown"],
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
    ]

    namespace = NetworkSettings.istio_namespace(config)
    name = "istiod-#{namespace}"

    B.build_resource(:cluster_role)
    |> B.name(name)
    |> B.app_labels(@istiod_app)
    |> Map.put("rules", rules)
  end

  def cluster_role_istiod_gateway(config) do
    rules = [
      %{
        "apiGroups" => [
          "apps"
        ],
        "resources" => [
          "deployments"
        ],
        "verbs" => [
          "get",
          "watch",
          "list",
          "update",
          "patch",
          "create",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "services"
        ],
        "verbs" => [
          "get",
          "watch",
          "list",
          "update",
          "patch",
          "create",
          "delete"
        ]
      }
    ]

    namespace = NetworkSettings.istio_namespace(config)
    name = "istiod-gateway-controller-#{namespace}"

    B.build_resource(:cluster_role)
    |> B.name(name)
    |> B.app_labels(@istiod_app)
    |> Map.put("rules", rules)
  end

  def cluster_role_reader(config) do
    rules = [
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
        "verbs" => ["get", "watch", "list"],
        "resources" => ["workloadentries"]
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
    ]

    namespace = NetworkSettings.istio_namespace(config)
    name = "istio-reader-#{namespace}"

    B.build_resource(:cluster_role)
    |> B.name(name)
    |> B.app_labels(@reader_app)
    |> Map.put("rules", rules)
  end

  def cluster_role_binding_reader(config) do
    namespace = NetworkSettings.istio_namespace(config)
    name = "istio-reader-#{namespace}"

    B.build_resource(:cluster_role_binding)
    |> B.name(name)
    |> B.app_labels(@reader_app)
    |> Map.put("roleRef", %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "ClusterRole",
      "name" => name
    })
    |> Map.put("subjects", [
      %{
        "kind" => "ServiceAccount",
        "name" => "istio-reader-service-account",
        "namespace" => namespace
      }
    ])
  end

  def cluster_role_binding_istiod(config) do
    namespace = NetworkSettings.istio_namespace(config)
    name = "istiod-#{namespace}"

    B.build_resource(:cluster_role_binding)
    |> B.name(name)
    |> B.app_labels(@istiod_app)
    |> Map.put("roleRef", %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "ClusterRole",
      "name" => name
    })
    |> Map.put("subjects", [
      %{
        "kind" => "ServiceAccount",
        "name" => "istiod",
        "namespace" => namespace
      }
    ])
  end

  def cluster_role_binding_istiod_gateway(config) do
    namespace = NetworkSettings.istio_namespace(config)

    name = "istiod-gateway-controller-#{namespace}"

    B.build_resource(:cluster_role_binding)
    |> B.name(name)
    |> B.app_labels(@istiod_app)
    |> Map.put("roleRef", %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "ClusterRole",
      "name" => name
    })
    |> Map.put("subjects", [
      %{
        "kind" => "ServiceAccount",
        "name" => "istiod",
        "namespace" => namespace
      }
    ])
  end

  def role_istiod(config) do
    namespace = NetworkSettings.istio_namespace(config)
    name = "istiod-#{namespace}"

    rules = [
      %{
        "apiGroups" => ["networking.istio.io"],
        "verbs" => ["create"],
        "resources" => ["gateways"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["create", "get", "watch", "list", "update", "delete"]
      }
    ]

    B.build_resource(:role)
    |> B.name(name)
    |> B.namespace(namespace)
    |> Map.put("rules", rules)
  end

  def role_binding_istiod(config) do
    namespace = NetworkSettings.istio_namespace(config)
    name = "istiod-#{namespace}"

    B.build_resource(:role_binding)
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.app_labels(@istiod_app)
    |> Map.put("roleRef", %{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Role",
      "name" => name
    })
    |> Map.put("subjects", [
      %{
        "kind" => "ServiceAccount",
        "name" => "istiod",
        "namespace" => namespace
      }
    ])
  end

  def validating_webhook_configuration(config) do
    namespace = NetworkSettings.istio_namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1",
      "kind" => "ValidatingWebhookConfiguration",
      "metadata" => %{
        "name" => "istiod-default-validator",
        "labels" => %{
          "battery/app" => @istiod_app,
          "istio" => "istiod",
          "istio.io/rev" => "default",
          "battery/managed" => "true"
        }
      },
      "webhooks" => [
        %{
          "name" => "validation.istio.io",
          "clientConfig" => %{
            "service" => %{
              "name" => "istiod",
              "namespace" => namespace,
              "path" => "/validate"
            }
          },
          "rules" => [
            %{
              "operations" => ["CREATE", "UPDATE"],
              "apiGroups" => ["security.istio.io", "networking.istio.io"],
              "apiVersions" => ["*"],
              "resources" => ["*"]
            }
          ],
          "failurePolicy" => "Ignore",
          "sideEffects" => "None",
          "admissionReviewVersions" => ["v1beta1", "v1"]
        }
      ]
    }
  end

  defp crd_content, do: unquote(File.read!(@crd_path))
end
