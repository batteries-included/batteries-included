defmodule CommonCore.Resources.CertManager.CertManager do
  @moduledoc false
  use CommonCore.IncludeResource,
    certificaterequests_cert_manager_io:
      "priv/manifests/cert_manager/cert_manager/certificaterequests_cert_manager_io.yaml",
    certificates_cert_manager_io: "priv/manifests/cert_manager/cert_manager/certificates_cert_manager_io.yaml",
    challenges_acme_cert_manager_io: "priv/manifests/cert_manager/cert_manager/challenges_acme_cert_manager_io.yaml",
    clusterissuers_cert_manager_io: "priv/manifests/cert_manager/cert_manager/clusterissuers_cert_manager_io.yaml",
    issuers_cert_manager_io: "priv/manifests/cert_manager/cert_manager/issuers_cert_manager_io.yaml",
    orders_acme_cert_manager_io: "priv/manifests/cert_manager/cert_manager/orders_acme_cert_manager_io.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "cert-manager"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  @lets_encrypt_staging_url "https://acme-staging-v02.api.letsencrypt.org/directory"
  @lets_encrypt_prod_url "https://acme-v02.api.letsencrypt.org/directory"

  resource(:cluster_role_binding_cert_manager_cainjector, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-cainjector")
    |> B.component_labels("cainjector")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-cainjector"))
    |> B.subject(B.build_service_account("cert-manager-cainjector", namespace))
  end

  resource(
    :cluster_role_binding_cert_manager_controller_approve_cert_manager_io,
    _battery,
    state
  ) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-approve:cert-manager-io")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-approve:cert-manager-io"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_cert_manager_controller_certificates, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-certificates")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-certificates"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(
    :cluster_role_binding_cert_manager_controller_certificatesigningrequests,
    _battery,
    state
  ) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-certificatesigningrequests")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-certificatesigningrequests"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_cert_manager_controller_challenges, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-challenges")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-challenges"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_cert_manager_controller_clusterissuers, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-clusterissuers")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-clusterissuers"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_cert_manager_controller_ingress_shim, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-ingress-shim")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-ingress-shim"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_cert_manager_controller_issuers, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-issuers")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-issuers"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_cert_manager_controller_orders, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-controller-orders")
    |> B.component_labels("controller")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-controller-orders"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:cluster_role_binding_cert_manager_webhook_subjectaccessreviews, _battery, state) do
    namespace = base_namespace(state)

    :cluster_role_binding
    |> B.build_resource()
    |> B.name("cert-manager-webhook:subjectaccessreviews")
    |> B.component_labels("webhook")
    |> B.role_ref(B.build_cluster_role_ref("cert-manager-webhook:subjectaccessreviews"))
    |> B.subject(B.build_service_account("cert-manager-webhook", namespace))
  end

  resource(:cluster_role_cert_manager_cainjector) do
    rules = [
      %{"apiGroups" => ["cert-manager.io"], "resources" => ["certificates"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["get", "create", "update", "patch"]},
      %{
        "apiGroups" => ["admissionregistration.k8s.io"],
        "resources" => ["validatingwebhookconfigurations", "mutatingwebhookconfigurations"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => ["apiregistration.k8s.io"],
        "resources" => ["apiservices"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      },
      %{
        "apiGroups" => ["apiextensions.k8s.io"],
        "resources" => ["customresourcedefinitions"],
        "verbs" => ["get", "list", "watch", "update", "patch"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-cainjector")
    |> B.component_labels("cainjector")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_approve_cert_manager_io) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resourceNames" => ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"],
        "resources" => ["signers"],
        "verbs" => ["approve"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-approve:cert-manager-io")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_certificates) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates", "certificates/status", "certificaterequests", "certificaterequests/status"],
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

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-certificates")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_certificatesigningrequests) do
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
      %{"apiGroups" => ["authorization.k8s.io"], "resources" => ["subjectaccessreviews"], "verbs" => ["create"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-certificatesigningrequests")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_challenges) do
    rules = [
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges", "challenges/status"],
        "verbs" => ["update", "patch"]
      },
      %{"apiGroups" => ["acme.cert-manager.io"], "resources" => ["challenges"], "verbs" => ["get", "list", "watch"]},
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
      %{"apiGroups" => ["route.openshift.io"], "resources" => ["routes/custom-host"], "verbs" => ["create"]},
      %{"apiGroups" => ["acme.cert-manager.io"], "resources" => ["challenges/finalizers"], "verbs" => ["update"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-challenges")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_clusterissuers) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["clusterissuers", "clusterissuers/status"],
        "verbs" => ["update", "patch"]
      },
      %{"apiGroups" => ["cert-manager.io"], "resources" => ["clusterissuers"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "create", "update", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-clusterissuers")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_ingress_shim) do
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
      %{"apiGroups" => ["networking.k8s.io"], "resources" => ["ingresses"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => ["networking.k8s.io"], "resources" => ["ingresses/finalizers"], "verbs" => ["update"]},
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

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-ingress-shim")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_issuers) do
    rules = [
      %{"apiGroups" => ["cert-manager.io"], "resources" => ["issuers", "issuers/status"], "verbs" => ["update", "patch"]},
      %{"apiGroups" => ["cert-manager.io"], "resources" => ["issuers"], "verbs" => ["get", "list", "watch"]},
      %{
        "apiGroups" => [""],
        "resources" => ["secrets"],
        "verbs" => ["get", "list", "watch", "create", "update", "delete"]
      },
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-issuers")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_controller_orders) do
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
      %{"apiGroups" => ["acme.cert-manager.io"], "resources" => ["challenges"], "verbs" => ["create", "delete"]},
      %{"apiGroups" => ["acme.cert-manager.io"], "resources" => ["orders/finalizers"], "verbs" => ["update"]},
      %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["get", "list", "watch"]},
      %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-controller-orders")
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_edit) do
    rules = [
      %{
        "apiGroups" => ["cert-manager.io"],
        "resources" => ["certificates", "certificaterequests", "issuers"],
        "verbs" => ["create", "delete", "deletecollection", "patch", "update"]
      },
      %{"apiGroups" => ["cert-manager.io"], "resources" => ["certificates/status"], "verbs" => ["update"]},
      %{
        "apiGroups" => ["acme.cert-manager.io"],
        "resources" => ["challenges", "orders"],
        "verbs" => ["create", "delete", "deletecollection", "patch", "update"]
      }
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-edit")
    |> B.component_labels("controller")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_view) do
    rules = [
      %{"apiGroups" => ["cert-manager.io"], "resources" => ["clusterissuers"], "verbs" => ["get", "list", "watch"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-cluster-view")
    |> B.component_labels("controller")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-cluster-reader", "true")
    |> B.rules(rules)
  end

  resource(:cluster_role_cert_manager_webhook_subjectaccessreviews) do
    rules = [
      %{"apiGroups" => ["authorization.k8s.io"], "resources" => ["subjectaccessreviews"], "verbs" => ["create"]}
    ]

    :cluster_role
    |> B.build_resource()
    |> B.name("cert-manager-webhook:subjectaccessreviews")
    |> B.component_labels("webhook")
    |> B.rules(rules)
  end

  resource(:config_map_cert_manager, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    :config_map
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.component_labels("controller")
    |> B.data(data)
  end

  resource(:config_map_cert_manager_webhook, _battery, state) do
    namespace = base_namespace(state)
    data = %{}

    :config_map
    |> B.build_resource()
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.component_labels("webhook")
    |> B.data(data)
  end

  resource(:crd_certificaterequests_cert_manager_io) do
    YamlElixir.read_all_from_string!(get_resource(:certificaterequests_cert_manager_io))
  end

  resource(:crd_certificates_cert_manager_io) do
    YamlElixir.read_all_from_string!(get_resource(:certificates_cert_manager_io))
  end

  resource(:crd_challenges_acme_cert_manager_io) do
    YamlElixir.read_all_from_string!(get_resource(:challenges_acme_cert_manager_io))
  end

  resource(:crd_clusterissuers_cert_manager_io) do
    YamlElixir.read_all_from_string!(get_resource(:clusterissuers_cert_manager_io))
  end

  resource(:crd_issuers_cert_manager_io) do
    YamlElixir.read_all_from_string!(get_resource(:issuers_cert_manager_io))
  end

  resource(:crd_orders_acme_cert_manager_io) do
    YamlElixir.read_all_from_string!(get_resource(:orders_acme_cert_manager_io))
  end

  resource(:deployment_cert_manager, battery, state) do
    namespace = base_namespace(state)
    component = "controller"

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "annotations" => %{
            "prometheus.io/path" => "/metrics",
            "prometheus.io/port" => "9402",
            "prometheus.io/scrape" => "true"
          },
          "labels" => %{
            "battery/app" => @app_name,
            "battery/component" => component,
            "battery/managed" => "true"
          }
        }
      )
      |> Map.put(
        "spec",
        %{
          "containers" => [
            %{
              "args" => [
                "--v=2",
                "--cluster-resource-namespace=$(POD_NAMESPACE)",
                "--leader-election-namespace=#{namespace}",
                "--acme-http01-solver-image=#{battery.config.acmesolver_image}",
                "--max-concurrent-challenges=60"
              ],
              "env" => [
                %{"name" => "POD_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}}
              ],
              "image" => battery.config.controller_image,
              "imagePullPolicy" => "IfNotPresent",
              "name" => "cert-manager-controller",
              "ports" => [
                %{"containerPort" => 9402, "name" => "http-metrics", "protocol" => "TCP"},
                %{"containerPort" => 9403, "name" => "http-healthz", "protocol" => "TCP"}
              ],
              "securityContext" => %{"allowPrivilegeEscalation" => false, "capabilities" => %{"drop" => ["ALL"]}}
            }
          ],
          "enableServiceLinks" => false,
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "securityContext" => %{"runAsNonRoot" => true, "seccompProfile" => %{"type" => "RuntimeDefault"}},
          "serviceAccountName" => @app_name
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)
      |> B.component_labels("controller")

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => component}}
      )
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.component_labels(component)
    |> B.spec(spec)
  end

  resource(:deployment_cert_manager_cainjector, battery, state) do
    namespace = base_namespace(state)
    component = "cainjector"

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/component" => component,
            "battery/managed" => "true"
          }
        }
      )
      |> Map.put(
        "spec",
        %{
          "containers" => [
            %{
              "args" => ["--v=2", "--leader-election-namespace=#{namespace}"],
              "env" => [
                %{"name" => "POD_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}}
              ],
              "image" => battery.config.cainjector_image,
              "imagePullPolicy" => "IfNotPresent",
              "name" => "cert-manager-cainjector",
              "securityContext" => %{"allowPrivilegeEscalation" => false, "capabilities" => %{"drop" => ["ALL"]}}
            }
          ],
          "enableServiceLinks" => false,
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "securityContext" => %{"runAsNonRoot" => true, "seccompProfile" => %{"type" => "RuntimeDefault"}},
          "serviceAccountName" => "cert-manager-cainjector"
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => component}}
      )
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("cert-manager-cainjector")
    |> B.namespace(namespace)
    |> B.component_labels(component)
    |> B.spec(spec)
  end

  resource(:deployment_cert_manager_webhook, battery, state) do
    namespace = base_namespace(state)
    component = "webhook"

    template =
      %{}
      |> Map.put(
        "metadata",
        %{
          "labels" => %{
            "battery/app" => @app_name,
            "battery/component" => component,
            "battery/managed" => "true"
          }
        }
      )
      |> Map.put(
        "spec",
        %{
          "containers" => [
            %{
              "args" => [
                "--v=2",
                "--secure-port=10250",
                "--dynamic-serving-ca-secret-namespace=$(POD_NAMESPACE)",
                "--dynamic-serving-ca-secret-name=cert-manager-webhook-ca",
                "--dynamic-serving-dns-names=cert-manager-webhook",
                "--dynamic-serving-dns-names=cert-manager-webhook.$(POD_NAMESPACE)",
                "--dynamic-serving-dns-names=cert-manager-webhook.$(POD_NAMESPACE).svc"
              ],
              "env" => [
                %{"name" => "POD_NAMESPACE", "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}}
              ],
              "image" => battery.config.webhook_image,
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
              "securityContext" => %{"allowPrivilegeEscalation" => false, "capabilities" => %{"drop" => ["ALL"]}}
            }
          ],
          "enableServiceLinks" => false,
          "nodeSelector" => %{"kubernetes.io/os" => "linux"},
          "securityContext" => %{"runAsNonRoot" => true, "seccompProfile" => %{"type" => "RuntimeDefault"}},
          "serviceAccountName" => "cert-manager-webhook"
        }
      )
      |> B.app_labels(@app_name)
      |> B.add_owner(battery)

    spec =
      %{}
      |> Map.put("replicas", 1)
      |> Map.put(
        "selector",
        %{"matchLabels" => %{"battery/app" => @app_name, "battery/component" => component}}
      )
      |> B.template(template)

    :deployment
    |> B.build_resource()
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.component_labels(component)
    |> B.spec(spec)
  end

  resource(:mutating_webhook_config_cert_manager, _battery, state) do
    namespace = base_namespace(state)

    :mutating_webhook_config
    |> B.build_resource()
    |> B.name("cert-manager-webhook")
    |> B.component_labels("webhook")
    |> B.annotation("cert-manager.io/inject-ca-from-secret", "#{namespace}/cert-manager-webhook-ca")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{"name" => "cert-manager-webhook", "namespace" => namespace, "path" => "/mutate"}
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

  resource(:role_binding_cert_manager_cainjector_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("cert-manager-cainjector:leaderelection")
    |> B.namespace(namespace)
    |> B.component_labels("cainjector")
    |> B.role_ref(B.build_role_ref("cert-manager-cainjector:leaderelection"))
    |> B.subject(B.build_service_account("cert-manager-cainjector", namespace))
  end

  resource(:role_binding_cert_manager_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("cert-manager:leaderelection")
    |> B.namespace(namespace)
    |> B.component_labels("controller")
    |> B.role_ref(B.build_role_ref("cert-manager:leaderelection"))
    |> B.subject(B.build_service_account(@app_name, namespace))
  end

  resource(:role_binding_cert_manager_startupapicheck_create_cert, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("cert-manager-startupapicheck:create-cert")
    |> B.namespace(namespace)
    |> B.component_labels("startupapicheck")
    |> B.role_ref(B.build_role_ref("cert-manager-startupapicheck:create-cert"))
    |> B.subject(B.build_service_account("cert-manager-startupapicheck", namespace))
  end

  resource(:role_binding_cert_manager_webhook_dynamic_serving, _battery, state) do
    namespace = base_namespace(state)

    :role_binding
    |> B.build_resource()
    |> B.name("cert-manager-webhook:dynamic-serving")
    |> B.namespace(namespace)
    |> B.component_labels("webhook")
    |> B.role_ref(B.build_role_ref("cert-manager-webhook:dynamic-serving"))
    |> B.subject(B.build_service_account("cert-manager-webhook", namespace))
  end

  resource(:role_cert_manager_cainjector_leaderelection, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{
        "apiGroups" => ["coordination.k8s.io"],
        "resourceNames" => ["cert-manager-cainjector-leader-election", "cert-manager-cainjector-leader-election-core"],
        "resources" => ["leases"],
        "verbs" => ["get", "update", "patch"]
      },
      %{"apiGroups" => ["coordination.k8s.io"], "resources" => ["leases"], "verbs" => ["create"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("cert-manager-cainjector:leaderelection")
    |> B.namespace(namespace)
    |> B.component_labels("cainjector")
    |> B.rules(rules)
  end

  resource(:role_cert_manager_leaderelection, _battery, state) do
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

    :role
    |> B.build_resource()
    |> B.name("cert-manager:leaderelection")
    |> B.namespace(namespace)
    |> B.component_labels("controller")
    |> B.rules(rules)
  end

  resource(:role_cert_manager_startupapicheck_create_cert, _battery, state) do
    namespace = base_namespace(state)

    rules = [
      %{"apiGroups" => ["cert-manager.io"], "resources" => ["certificates"], "verbs" => ["create"]}
    ]

    :role
    |> B.build_resource()
    |> B.name("cert-manager-startupapicheck:create-cert")
    |> B.namespace(namespace)
    |> B.component_labels("startupapicheck")
    |> B.rules(rules)
  end

  resource(:role_cert_manager_webhook_dynamic_serving, _battery, state) do
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

    :role
    |> B.build_resource()
    |> B.name("cert-manager-webhook:dynamic-serving")
    |> B.namespace(namespace)
    |> B.component_labels("webhook")
    |> B.rules(rules)
  end

  resource(:service_account_cert_manager, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.component_labels("controller")
  end

  resource(:service_account_cert_manager_cainjector, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("cert-manager-cainjector")
    |> B.namespace(namespace)
    |> B.component_labels("cainjector")
  end

  resource(:service_account_cert_manager_startupapicheck, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("cert-manager-startupapicheck")
    |> B.namespace(namespace)
    |> B.component_labels("startupapicheck")
  end

  resource(:service_account_cert_manager_webhook, _battery, state) do
    namespace = base_namespace(state)

    :service_account
    |> B.build_resource()
    |> Map.put("automountServiceAccountToken", true)
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.component_labels("webhook")
  end

  resource(:service_cert_manager, _battery, state) do
    namespace = base_namespace(state)
    component = "controller"

    spec =
      %{}
      |> Map.put("ports", [
        %{"name" => "tcp-prometheus-servicemonitor", "port" => 9402, "protocol" => "TCP", "targetPort" => 9402}
      ])
      |> Map.put(
        "selector",
        %{"battery/app" => @app_name, "battery/component" => component}
      )
      |> Map.put("type", "ClusterIP")

    :service
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.component_labels(component)
    |> B.spec(spec)
  end

  resource(:service_cert_manager_webhook, _battery, state) do
    namespace = base_namespace(state)
    component = "webhook"

    spec =
      %{}
      |> Map.put("ports", [%{"name" => "https", "port" => 443, "protocol" => "TCP", "targetPort" => "https"}])
      |> Map.put("selector", %{"battery/app" => @app_name, "battery/component" => component})
      |> Map.put("type", "ClusterIP")

    :service
    |> B.build_resource()
    |> B.name("cert-manager-webhook")
    |> B.namespace(namespace)
    |> B.component_labels(component)
    |> B.spec(spec)
  end

  resource(:validating_webhook_config_cert_manager, _battery, state) do
    namespace = base_namespace(state)

    :validating_webhook_config
    |> B.build_resource()
    |> B.name("cert-manager-webhook")
    |> B.component_labels("webhook")
    |> B.annotation("cert-manager.io/inject-ca-from-secret", "#{namespace}/cert-manager-webhook-ca")
    |> Map.put("webhooks", [
      %{
        "admissionReviewVersions" => ["v1"],
        "clientConfig" => %{
          "service" => %{"name" => "cert-manager-webhook", "namespace" => namespace, "path" => "/validate"}
        },
        "failurePolicy" => "Fail",
        "matchPolicy" => "Equivalent",
        "name" => "webhook.cert-manager.io",
        "namespaceSelector" => %{
          "matchExpressions" => [
            %{"key" => "cert-manager.io/disable-validation", "operator" => "NotIn", "values" => ["true"]}
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
      |> Map.put("jobLabel", @app_name)
      |> Map.put(
        "selector",
        %{
          "matchLabels" => %{
            "battery/app" => @app_name,
            "battery/component" => component
          }
        }
      )

    :monitoring_service_monitor
    |> B.build_resource()
    |> B.name("cert-manager")
    |> B.namespace(namespace)
    |> B.component_labels(component)
    |> B.label("prometheus", "default")
    |> B.spec(spec)
    |> F.require_battery(state, :victoria_metrics)
  end

  resource(:lets_encrypt_cluster_issuer_stage, battery) do
    name = "lets-encrypt-stage"

    spec = %{
      "acme" => %{
        "server" => @lets_encrypt_staging_url,
        "email" => battery.config.email,
        "privateKeySecretRef" => %{"name" => name},
        "solvers" => [%{"http01" => %{"ingress" => %{"ingressClassName" => "cert-manager"}}}]
      }
    }

    :certmanager_cluster_issuer
    |> B.build_resource()
    |> B.name(name)
    |> B.spec(spec)
  end

  resource(:lets_encrypt_cluster_issuer, battery) do
    name = "lets-encrypt"

    spec = %{
      "acme" => %{
        "server" => @lets_encrypt_prod_url,
        "email" => battery.config.email,
        "privateKeySecretRef" => %{"name" => name},
        "solvers" => [%{"http01" => %{"ingress" => %{"ingressClassName" => "cert-manager"}}}]
      }
    }

    :certmanager_cluster_issuer
    |> B.build_resource()
    |> B.name(name)
    |> B.spec(spec)
  end

  # This ingress class is used to present HTTP01 challenges
  resource(:cert_manager_ingress_class) do
    spec = %{"controller" => "istio.io/ingress-controller"}

    :ingress_class
    |> B.build_resource()
    |> B.name("cert-manager")
    |> B.spec(spec)
  end
end
