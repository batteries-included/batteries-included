defmodule KubeResources.CertManager do
  use KubeExt.IncludeResource,
    certificaterequests_cert_manager_io:
      "priv/manifests/cert_manager/certificaterequests_cert_manager_io.yaml",
    certificates_cert_manager_io: "priv/manifests/cert_manager/certificates_cert_manager_io.yaml",
    challenges_acme_cert_manager_io:
      "priv/manifests/cert_manager/challenges_acme_cert_manager_io.yaml",
    clusterissuers_cert_manager_io:
      "priv/manifests/cert_manager/clusterissuers_cert_manager_io.yaml",
    issuers_cert_manager_io: "priv/manifests/cert_manager/issuers_cert_manager_io.yaml",
    orders_acme_cert_manager_io: "priv/manifests/cert_manager/orders_acme_cert_manager_io.yaml"

  use KubeExt.ResourceGenerator

  import KubeExt.Yaml
  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B
  alias KubeExt.FilterResource, as: F

  @app_name "cert-manager"

  resource(:cluster_role_binding_cainjector, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-cainjector")
    |> B.app_labels(@app_name)
    |> B.component_label("cainjector")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-cainjector"))
    |> B.subject(B.build_service_account("cert-manager-cainjector", namespace))
  end

  resource(:cluster_role_binding_controller_approve_io, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-approve:cert-manager-io")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-approve:cert-manager-io"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_controller_certificates, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-certificates")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-certificates"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_controller_certificatesigningrequests, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-certificatesigningrequests")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-certificatesigningrequests"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_controller_challenges, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-challenges")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-challenges"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_controller_clusterissuers, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-clusterissuers")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-clusterissuers"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_controller_ingress_shim, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-ingress-shim")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-ingress-shim"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_controller_issuers, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-issuers")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-issuers"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_controller_orders, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-controller-orders")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-orders"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:cluster_role_binding_webhook_subjectaccessreviews, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:cluster_role_binding)
    |> B.name("cert-manager-webhook:subjectaccessreviews")
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-webhook:subjectaccessreviews"))
    |> B.subject(B.build_service_account("cert-manager-webhook", namespace))
  end

  resource(:cluster_role_cainjector) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["events"],
        "verbs" => ["get", "create", "update", "patch"]
      },
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["apiregistration.k8s.io"],
        "resources" => ["apiservices"],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch", "update"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-cainjector")
    |> B.app_labels(@app_name)
    |> B.component_label("cainjector")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_approve_io) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resourceNames" => ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"],
        "resources" => ["signers"],
        "verbs" => ["approve"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-approve:cert-manager-io")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_controller_certificates) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => [
          "certificates",
          "certificates/status",
          "certificaterequests",
          "certificaterequests/status"
        ],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates", "certificaterequests", "clusterissuers", "issuers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates/finalizers", "certificaterequests/finalizers"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["orders"],
        "verbs" => ["create", "delete", "get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "create", "update", "delete", "patch"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-certificates")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_controller_certificatesigningrequests) do
    rules = [
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resources" => ["certificatesigningrequests"],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resources" => ["certificatesigningrequests/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["certificates.k8s.io"],
        "resourceNames" => ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"],
        "resources" => ["signers"],
        "verbs" => ["sign"]
      },
      %{
        "apiGroups" => ["authorization.k8s.io"],
        "resources" => ["subjectaccessreviews"],
        "verbs" => ["create"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-certificatesigningrequests")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_controller_challenges) do
    rules = [
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges", "challenges/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["issuers", "clusterissuers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["pods", "services"],
        "verbs" => ["get", "list", "watch", "create", "delete"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch", "create", "delete", "update"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["httproutes"],
        "verbs" => ["get", "list", "watch", "create", "delete", "update"]
      },
      %{
        "apiGroups" => ["route.openshift.io"],
        "resources" => ["routes/custom-host"],
        "verbs" => ["create"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges/finalizers"],
        "verbs" => ["update"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-challenges")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_controller_clusterissuers) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["clusterissuers", "clusterissuers/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["clusterissuers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "create", "update", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-clusterissuers")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_controller_ingress_shim) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates", "certificaterequests"],
        "verbs" => ["create", "update", "delete"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates", "certificaterequests", "issuers", "clusterissuers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["networking.k8s.io"],
        "resources" => ["ingresses/finalizers"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["gateways", "httproutes"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["gateway.networking.k8s.io"],
        "resources" => ["gateways/finalizers", "httproutes/finalizers"],
        "verbs" => ["update"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-ingress-shim")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_controller_issuers) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["issuers", "issuers/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["issuers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "create", "update", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-issuers")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_controller_orders) do
    rules = [
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["orders", "orders/status"],
        "verbs" => ["update", "patch"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["orders", "challenges"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["clusterissuers", "issuers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges"],
        "verbs" => ["create", "delete"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["orders/finalizers"],
        "verbs" => ["update"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-controller-orders")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_edit) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates", "certificaterequests", "issuers"],
        "verbs" => ["create", "delete", "deletecollection", "patch", "update"]
      },
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates/status"],
        "verbs" => ["update"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges", "orders"],
        "verbs" => ["create", "delete", "deletecollection", "patch", "update"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-edit")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_view) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates", "certificaterequests", "issuers"],
        "verbs" => ["get", "list", "watch"]
      },
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges", "orders"],
        "verbs" => ["get", "list", "watch"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-view")
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_webhook_subjectaccessreviews) do
    rules = [
      %{
        "apiGroups" => ["authorization.k8s.io"],
        "resources" => ["subjectaccessreviews"],
        "verbs" => ["create"]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name("cert-manager-webhook:subjectaccessreviews")
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> B.rules(rules)
  end

  resource(:config_map_webhook, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    B.build_resource(:config_map)
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> B.data(data)
  end

  resource(:crd_certificaterequests_io) do
    yaml(get_resource(:certificaterequests_cert_manager_io))
  end

  resource(:crd_certificates_io) do
    yaml(get_resource(:certificates_cert_manager_io))
  end

  resource(:crd_challenges_acme_io) do
    yaml(get_resource(:challenges_acme_cert_manager_io))
  end

  resource(:crd_clusterissuers_io) do
    yaml(get_resource(:clusterissuers_cert_manager_io))
  end

  resource(:crd_issuers_io) do
    yaml(get_resource(:issuers_cert_manager_io))
  end

  resource(:crd_orders_acme_io) do
    yaml(get_resource(:orders_acme_cert_manager_io))
  end

  resource(:deployment_cert_manager, _battery, state) do
    namespace = base_namespace(state)
    component = "controller"

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "battery/component" => component
          }
        }
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => component
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--v=4",
                  "--cluster-resource-namespace=$(POD_NAMESPACE)",
                  "--leader-election-namespace=$(POD_NAMESPACE)"
                ],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  }
                ],
                "image" => "quay.io/jetstack/cert-manager-controller:v1.10.1",
                "imagePullPolicy" => "IfNotPresent",
                "name" => "cert-manager-controller",
                "ports" => [
                  %{"containerPort" => 9402, "name" => "http-metrics", "protocol" => "TCP"}
                ],
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]}
                }
              }
            ],
            "nodeSelector" => %{"kubernetes.io/os" => "linux"},
            "securityContext" => %{
              "runAsNonRoot" => true,
              "seccompProfile" => %{"type" => "RuntimeDefault"}
            },
            "serviceAccountName" => "cert-manager"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("cert-manager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label(component)
    |> B.spec(spec)
  end

  resource(:deployment_cainjector, _battery, state) do
    namespace = base_namespace(state)
    component = "cainjector"

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{"battery/app" => @app_name, "battery/component" => component}
        }
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => component
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => ["--v=2", "--leader-election-namespace=$(POD_NAMESPACE)"],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  }
                ],
                "image" => "quay.io/jetstack/cert-manager-cainjector:v1.10.1",
                "imagePullPolicy" => "IfNotPresent",
                "name" => "cert-manager-cainjector",
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]}
                }
              }
            ],
            "nodeSelector" => %{"kubernetes.io/os" => "linux"},
            "securityContext" => %{
              "runAsNonRoot" => true,
              "seccompProfile" => %{"type" => "RuntimeDefault"}
            },
            "serviceAccountName" => "cert-manager-cainjector"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("cert-manager-cainjector")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label(component)
    |> B.spec(spec)
  end

  resource(:deployment_webhook, _battery, state) do
    namespace = base_namespace(state)
    component = "webhook"

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => component}}
      )
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name,
              "battery/component" => component
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--v=4",
                  "--secure-port=10250",
                  "--dynamic-serving-ca-secret-namespace=$(POD_NAMESPACE)",
                  "--dynamic-serving-ca-secret-name=cert-manager-webhook-ca",
                  "--dynamic-serving-dns-names=cert-manager-webhook",
                  "--dynamic-serving-dns-names=cert-manager-webhook.$(POD_NAMESPACE)",
                  "--dynamic-serving-dns-names=cert-manager-webhook.$(POD_NAMESPACE).svc"
                ],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  }
                ],
                "image" => "quay.io/jetstack/cert-manager-webhook:v1.10.1",
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/livez", "port" => 6080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 60,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "name" => "cert-manager-webhook",
                "ports" => [
                  %{"containerPort" => 10_250, "name" => "https", "protocol" => "TCP"},
                  %{"containerPort" => 6080, "name" => "healthcheck", "protocol" => "TCP"}
                ],
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{"path" => "/healthz", "port" => 6080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 5,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]}
                }
              }
            ],
            "nodeSelector" => %{"kubernetes.io/os" => "linux"},
            "securityContext" => %{
              "runAsNonRoot" => true,
              "seccompProfile" => %{"type" => "RuntimeDefault"}
            },
            "serviceAccountName" => "cert-manager-webhook"
          }
        }
      )

    B.build_resource(:deployment)
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label(component)
    |> B.spec(spec)
  end

  resource(:job_startupapicheck, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("backoffLimit", 4)
      |> Map.put(
        "template",
        %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => @app_name
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => ["check", "api", "--wait=1m"],
                "image" => "quay.io/jetstack/cert-manager-ctl:v1.10.1",
                "imagePullPolicy" => "IfNotPresent",
                "name" => "cert-manager-startupapicheck",
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{"drop" => ["ALL"]}
                }
              }
            ],
            "nodeSelector" => %{"kubernetes.io/os" => "linux"},
            "restartPolicy" => "OnFailure",
            "securityContext" => %{
              "runAsNonRoot" => true,
              "seccompProfile" => %{"type" => "RuntimeDefault"}
            },
            "serviceAccountName" => "cert-manager-startupapicheck"
          }
        }
      )

    B.build_resource(:job)
    |> B.name("cert-manager-startupapicheck")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("startupapicheck")
    |> B.spec(spec)
  end

  resource(:mutating_webhook_config_cert_manager, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:mutating_webhook_config)
    |> B.name("cert-manager-webhook")
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> B.annotation(
      "cert-manager.io/inject-ca-from-secret",
      "#{namespace}/cert-manager-webhook-ca"
    )
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "cert-manager-webhook",
            "namespace" => namespace,
            "path" => "/mutate"
          }
        },
        "failurePolicy" => "Fail",
        "matchPolicy" => "Equivalent",
        "name" => "webhook.cert-manager.io",
        "rules" => [
          %{
            "apiGroups" => ["cert-manager.io", "acme.cert-manager.io"],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["*/*"]
          }
        ],
        "sideEffects" => "None",
        "timeoutSeconds" => 10
      }
    ])
  end

  resource(:role_binding_cainjector_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("cert-manager-cainjector:leaderelection")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("cainjector")
    |> B.role_ref(B.build_role_ref("cert-manager-cainjector:leaderelection"))
    |> B.subject(B.build_service_account("cert-manager-cainjector", namespace))
  end

  resource(:role_binding_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("cert-manager:leaderelection")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.role_ref(B.build_role_ref("cert-manager:leaderelection"))
    |> B.subject(B.build_service_account("cert-manager", namespace))
  end

  resource(:role_binding_startupapicheck_create_cert, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("cert-manager-startupapicheck:create-cert")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("startupapicheck")
    |> B.role_ref(B.build_role_ref("cert-manager-startupapicheck:create-cert"))
    |> B.subject(B.build_service_account("cert-manager-startupapicheck", namespace))
  end

  resource(:role_binding_webhook_dynamic_serving, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:role_binding)
    |> B.name("cert-manager-webhook:dynamic-serving")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> B.role_ref(B.build_role_ref("cert-manager-webhook:dynamic-serving"))
    |> B.subject(B.build_service_account("cert-manager-webhook", namespace))
  end

  resource(:role_cainjector_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => [
          "cert-manager-cainjector-leader-election",
          "cert-manager-cainjector-leader-election-core"
        ],
        "resources" => ["leases"],
        "verbs" => ["get", "update", "patch"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create"]}
    ]

    B.build_resource(:role)
    |> B.name("cert-manager-cainjector:leaderelection")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("cainjector")
    |> B.rules(rules)
  end

  resource(:role_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => ["cert-manager-controller"],
        "resources" => ["leases"],
        "verbs" => ["get", "update", "patch"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create"]}
    ]

    B.build_resource(:role)
    |> B.name("cert-manager:leaderelection")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
    |> B.rules(rules)
  end

  resource(:role_startupapicheck_create_cert, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates"],
        "verbs" => ["create"]
      }
    ]

    B.build_resource(:role)
    |> B.name("cert-manager-startupapicheck:create-cert")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("startupapicheck")
    |> B.rules(rules)
  end

  resource(:role_webhook_dynamic_serving, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => [""],
        "resourceNames" => ["cert-manager-webhook-ca"],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "update"]
      },
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["create"]}
    ]

    B.build_resource(:role)
    |> B.name("cert-manager-webhook:dynamic-serving")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> B.rules(rules)
  end

  resource(:service_account_cert_manager, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("cert-manager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("controller")
  end

  resource(:service_account_cainjector, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> B.name("cert-manager-cainjector")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("cainjector")
    |> Map.put("automountServiceAccountToken", true)
  end

  resource(:service_account_startupapicheck, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> B.name("cert-manager-startupapicheck")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("startupapicheck")
    |> Map.put("automountServiceAccountToken", true)
  end

  resource(:service_account_webhook, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:service_account)
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> Map.put("automountServiceAccountToken", true)
  end

  resource(:service_cert_manager, _battery, state) do
    namespace = base_namespace(state)
    component = "controller"

    spec =
      %{}
      |> Map.put("ports", [
        %{
          "name" => "tcp-prometheus-servicemonitor",
          "port" => 9402,
          "protocol" => "TCP",
          "targetPort" => 9402
        }
      ])
      |> Map.put(
        "selector",
        %{"battery/app" => @app_name, "battery/component" => component}
      )
      |> Map.put("type", "ClusterIP")

    B.build_resource(:service)
    |> B.name("cert-manager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label(component)
    |> B.spec(spec)
  end

  resource(:service_webhook, _battery, state) do
    namespace = base_namespace(state)
    component = "webhook"

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => "https"}
      ])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => component})

    B.build_resource(:service)
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label(component)
    |> B.spec(spec)
  end

  resource(:service_monitor_cert_manager, _battery, state) do
    namespace = base_namespace(state)
    component = "controller"

    spec =
      %{}
      |> Map.put("endpoints", [
        %{
          "honorLabels" => false,
          "interval" => "60s",
          "path" => "/metrics",
          "scrapeTimeout" => "30s",
          "targetPort" => 9402
        }
      ])
      |> Map.put("jobLabel", "cert-manager")
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "battery/component" => component
          }
        }
      )

    B.build_resource(:monitoring_service_monitor)
    |> B.name("cert-manager")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.component_label(component)
    |> B.label("prometheus", "default")
    |> B.spec(spec)
    |> F.require_battery(state, :prometheus)
  end

  resource(:validating_webhook_config_cert_manager, _battery, state) do
    namespace = base_namespace(state)

    B.build_resource(:validating_webhook_config)
    |> B.name("cert-manager-webhook")
    |> B.app_labels(@app_name)
    |> B.component_label("webhook")
    |> B.annotation(
      "cert-manager.io/inject-ca-from-secret",
      "#{namespace}/cert-manager-webhook-ca"
    )
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{
            "name" => "cert-manager-webhook",
            "namespace" => namespace,
            "path" => "/validate"
          }
        },
        "failurePolicy" => "Fail",
        "matchPolicy" => "Equivalent",
        "name" => "webhook.cert-manager.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{
              "key" => "cert-manager.io/disable-validation",
              "operator" => "NotIn",
              "values" => ["true"]
            },
            %{"key" => "name", "operator" => "NotIn", "values" => [namespace]}
          ]
        },
        "rules" => [
          %{
            "apiGroups" => ["cert-manager.io", "acme.cert-manager.io"],
            "apiVersions" => ["v1"],
            "operations" => ["CREATE", "UPDATE"],
            "resources" => ["*/*"]
          }
        ],
        "sideEffects" => "None",
        "timeoutSeconds" => 10
      }
    ])
  end
end
