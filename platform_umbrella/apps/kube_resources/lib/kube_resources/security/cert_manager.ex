defmodule KubeResources.CertManager do
  @moduledoc false

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeResources.SecuritySettings

  @app "cert-manager"
  @crd_path "priv/manifests/cert_manager/cert-manager.crds.yaml"

  @cainjector_service_account "cert-manager-cainjector"
  @webhook_service_account "cert-manager-webhook"
  @cert_manager_service_account "cert-manager"
  @cert_manager_startup_check_service_account "cert-manager-startupapicheck"

  @webhook_config "cert-manager-webhook"

  @cainjector_cluster_role "battery-cert-manager:cainjector"
  @cainjector_leader_role "battery-cert-manager-cainjector:leader"

  @issuers_cluster_role "battery-cert-manager-controller:issuers"
  @cluster_issuers_cluster_role "battery-cert-manager-controller:clusterissuers"
  @certs_cluster_role "battery-cert-manager-controller:certificates"
  @orders_cluster_role "battery-cert-manager-controller:orders"
  @challenges_cluster_role "battery-cert-manager-controller:challenges"
  @ingress_shim_cluster_role "battery-cert-manager-controller:ingress-shim"
  @approve_cluster_role "battery-cert-manager-controller:approve"
  @sign_request_cluster_role "battery-cert-manager-controller:signrequest"
  @leader_role "battery-cert-manager:leader"

  @webhook_subject_access_cluster_role "battery-cert-mangaer-webhook:subjectaccessreviews"
  @webhook_dynamic_serving_role "cert-manager-webhook:dynamic-serving"

  @view_cluster_role "battery-cert-manager-view"
  @edit_cluster_role "battery-cert-manager-edit"

  @startup_role "cert-manager-startupapicheck:create-cert"

  @cert_manager_service "cert-manager"
  @webhook_service "cert-manager-webhook"

  def service_account(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name(@cainjector_service_account)
    |> Map.put("automountServiceAccountToken", true)
  end

  def service_account_1(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name(@cert_manager_service_account)
    |> Map.put("automountServiceAccountToken", true)
  end

  def service_account_2(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name(@webhook_service_account)
    |> Map.put("automountServiceAccountToken", true)
  end

  def config_map(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:config_map)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name(@webhook_config)
  end

  def cluster_role(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "get",
          "create",
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "admissionregistration.k8s.io"
        ],
        "resources" => [
          "validatingwebhookconfigurations",
          "mutatingwebhookconfigurations"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "apiregistration.k8s.io"
        ],
        "resources" => [
          "apiservices"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resources" => [
          "customresourcedefinitions"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "update"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@cainjector_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_1(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "issuers",
          "issuers/status"
        ],
        "verbs" => [
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "issuers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "patch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@issuers_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_2(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "clusterissuers",
          "clusterissuers/status"
        ],
        "verbs" => [
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "clusterissuers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "patch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@cluster_issuers_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_3(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates",
          "certificates/status",
          "certificaterequests",
          "certificaterequests/status"
        ],
        "verbs" => [
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates",
          "certificaterequests",
          "clusterissuers",
          "issuers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates/finalizers",
          "certificaterequests/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "orders"
        ],
        "verbs" => [
          "create",
          "delete",
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "update",
          "delete",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "patch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@certs_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_4(_config) do
    rules = [
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "orders",
          "orders/status"
        ],
        "verbs" => [
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "orders",
          "challenges"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "clusterissuers",
          "issuers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "challenges"
        ],
        "verbs" => [
          "create",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "orders/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "patch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@orders_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_5(_config) do
    rules = [
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "challenges",
          "challenges/status"
        ],
        "verbs" => [
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "challenges"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "issuers",
          "clusterissuers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "pods",
          "services"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "networking.k8s.io"
        ],
        "resources" => [
          "ingresses"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "delete",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "gateway.networking.k8s.io"
        ],
        "resources" => [
          "httproutes"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "delete",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "route.openshift.io"
        ],
        "resources" => [
          "routes/custom-host"
        ],
        "verbs" => [
          "create"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "challenges/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@challenges_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_6(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates",
          "certificaterequests"
        ],
        "verbs" => [
          "create",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates",
          "certificaterequests",
          "issuers",
          "clusterissuers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "networking.k8s.io"
        ],
        "resources" => [
          "ingresses"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "networking.k8s.io"
        ],
        "resources" => [
          "ingresses/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "gateway.networking.k8s.io"
        ],
        "resources" => [
          "gateways",
          "httproutes"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "gateway.networking.k8s.io"
        ],
        "resources" => [
          "gateways/finalizers",
          "httproutes/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "events"
        ],
        "verbs" => [
          "create",
          "patch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@ingress_shim_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_7(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates",
          "certificaterequests",
          "issuers"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "challenges",
          "orders"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@view_cluster_role)
    |> B.rules(rules)
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
  end

  def cluster_role_8(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates",
          "certificaterequests",
          "issuers"
        ],
        "verbs" => [
          "create",
          "delete",
          "deletecollection",
          "patch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates/status"
        ],
        "verbs" => [
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "acme.cert-manager.io"
        ],
        "resources" => [
          "challenges",
          "orders"
        ],
        "verbs" => [
          "create",
          "delete",
          "deletecollection",
          "patch",
          "update"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@edit_cluster_role)
    |> B.rules(rules)
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
  end

  def cluster_role_9(_config) do
    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resourceNames" => [
          "issuers.cert-manager.io/*",
          "clusterissuers.cert-manager.io/*"
        ],
        "resources" => [
          "signers"
        ],
        "verbs" => [
          "approve"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@approve_cluster_role)
    |> B.rules(rules)

    # %{
    #   "apiVersion" => "rbac.authorization.k8s.io/v1",
    #   "kind" => "ClusterRole",
    #   "metadata" => %{
    #     "labels" => %{
    #       "app.kubernetes.io/component" => "cert-manager",
    #       "app.kubernetes.io/instance" => "cert-manager",
    #       "battery/app" => "cert-manager",
    #       "battery/managed" => "true"
    #     },
    #     "name" => "cert-manager-controller-approve:cert-manager-io"
    #   },
    #   "rules" =>
    # }
  end

  def cluster_role_10(_config) do
    rules = [
      %{
        "apiGroups" => [
          "certificates.k8s.io"
        ],
        "resources" => [
          "certificatesigningrequests"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "certificates.k8s.io"
        ],
        "resources" => [
          "certificatesigningrequests/status"
        ],
        "verbs" => [
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "certificates.k8s.io"
        ],
        "resourceNames" => [
          "issuers.cert-manager.io/*",
          "clusterissuers.cert-manager.io/*"
        ],
        "resources" => [
          "signers"
        ],
        "verbs" => [
          "sign"
        ]
      },
      %{
        "apiGroups" => [
          "authorization.k8s.io"
        ],
        "resources" => [
          "subjectaccessreviews"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@sign_request_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_11(_config) do
    rules = [
      %{
        "apiGroups" => [
          "authorization.k8s.io"
        ],
        "resources" => [
          "subjectaccessreviews"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.app_labels(@app)
    |> B.name(@webhook_subject_access_cluster_role)
    |> B.rules(rules)
  end

  def cluster_role_binding(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@cainjector_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@cainjector_cluster_role))
    |> B.subject(B.build_service_account(@cainjector_service_account, namespace))
  end

  def cluster_role_binding_1(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@issuers_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@issuers_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_2(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@cluster_issuers_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@cluster_issuers_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_3(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@certs_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@certs_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_4(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@orders_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@orders_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_5(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@challenges_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@challenges_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_6(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@ingress_shim_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@ingress_shim_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_7(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@approve_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@approve_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_8(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@sign_request_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@sign_request_cluster_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def cluster_role_binding_9(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@webhook_subject_access_cluster_role)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@webhook_subject_access_cluster_role))
    |> B.subject(B.build_service_account(@webhook_service_account, namespace))
  end

  def role(_config) do
    rules = [
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resourceNames" => [
          "cert-manager-cainjector-leader-election",
          "cert-manager-cainjector-leader-election-core"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "get",
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.app_labels(@app)
    |> B.name(@cainjector_leader_role)
    |> B.namespace("kube-system")
    |> B.rules(rules)
  end

  def role_1(_config) do
    rules = [
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resourceNames" => [
          "cert-manager-controller"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "get",
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.app_labels(@app)
    |> B.name(@leader_role)
    |> B.namespace("kube-system")
    |> B.rules(rules)
  end

  def role_2(config) do
    namespace = SecuritySettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          "cert-manager-webhook-ca"
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.app_labels(@app)
    |> B.name(@webhook_dynamic_serving_role)
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  def role_binding(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@cainjector_leader_role)
    |> B.namespace("kube-system")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref(@cainjector_leader_role))
    |> B.subject(B.build_service_account(@cainjector_service_account, namespace))
  end

  def role_binding_1(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@leader_role)
    |> B.namespace("kube-system")
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref(@leader_role))
    |> B.subject(B.build_service_account(@cert_manager_service_account, namespace))
  end

  def role_binding_2(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@webhook_dynamic_serving_role)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref(@webhook_dynamic_serving_role))
    |> B.subject(B.build_service_account(@webhook_service_account, namespace))
  end

  def service(config) do
    namespace = SecuritySettings.namespace(config)

    spec = %{
      "ports" => [
        %{
          "name" => "tcp-prometheus-servicemonitor",
          "port" => 9402,
          "protocol" => "TCP",
          "targetPort" => 9402
        }
      ],
      "selector" => %{
        "app.kubernetes.io/component" => "controller",
        "battery/app" => "cert-manager"
      }
    }

    B.build_resource(:service)
    |> B.name(@cert_manager_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def service_1(config) do
    namespace = SecuritySettings.namespace(config)

    spec = %{
      "ports" => [
        %{
          "name" => "https",
          "port" => 443,
          "protocol" => "TCP",
          "targetPort" => "https"
        }
      ],
      "selector" => %{
        "app.kubernetes.io/component" => "webhook",
        "app.kubernetes.io/instance" => "cert-manager"
      }
    }

    B.build_resource(:service)
    |> B.name(@webhook_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "cainjector",
          "app.kubernetes.io/instance" => "cert-manager",
          "battery/app" => "cainjector",
          "battery/managed" => "true"
        },
        "name" => "cert-manager-cainjector",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/component" => "cainjector",
            "app.kubernetes.io/instance" => "cert-manager",
            "battery/managed" => "true"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/component" => "cainjector",
              "app.kubernetes.io/instance" => "cert-manager",
              "battery/app" => "cainjector",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--v=2",
                  "--leader-election-namespace=kube-system"
                ],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "fieldPath" => "metadata.namespace"
                      }
                    }
                  }
                ],
                "image" => "quay.io/jetstack/cert-manager-cainjector:v1.8.0",
                "imagePullPolicy" => "IfNotPresent",
                "name" => "cert-manager",
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false
                }
              }
            ],
            "nodeSelector" => %{
              "kubernetes.io/os" => "linux"
            },
            "securityContext" => %{
              "runAsNonRoot" => true
            },
            "serviceAccountName" => "cert-manager-cainjector"
          }
        }
      }
    }
  end

  def deployment_1(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "controller",
          "app.kubernetes.io/instance" => "cert-manager",
          "battery/app" => "cert-manager",
          "battery/managed" => "true"
        },
        "name" => "cert-manager",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/component" => "controller",
            "app.kubernetes.io/instance" => "cert-manager",
            "battery/managed" => "true"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/component" => "controller",
              "app.kubernetes.io/instance" => "cert-manager",
              "battery/app" => "cert-manager",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--v=2",
                  "--cluster-resource-namespace=$(POD_NAMESPACE)",
                  "--leader-election-namespace=kube-system"
                ],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "fieldPath" => "metadata.namespace"
                      }
                    }
                  }
                ],
                "image" => "quay.io/jetstack/cert-manager-controller:v1.8.0",
                "imagePullPolicy" => "IfNotPresent",
                "name" => "cert-manager",
                "ports" => [
                  %{
                    "containerPort" => 9402,
                    "name" => "http-metrics",
                    "protocol" => "TCP"
                  }
                ],
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false
                }
              }
            ],
            "nodeSelector" => %{
              "kubernetes.io/os" => "linux"
            },
            "securityContext" => %{
              "runAsNonRoot" => true
            },
            "serviceAccountName" => "cert-manager"
          }
        }
      }
    }
  end

  def deployment_2(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "webhook",
          "app.kubernetes.io/instance" => "cert-manager",
          "battery/app" => "webhook",
          "battery/managed" => "true"
        },
        "name" => "cert-manager-webhook",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/component" => "webhook",
            "app.kubernetes.io/instance" => "cert-manager",
            "battery/managed" => "true"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/component" => "webhook",
              "app.kubernetes.io/instance" => "cert-manager",
              "battery/app" => "webhook",
              "battery/managed" => "true"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "--v=2",
                  "--secure-port=10250",
                  "--dynamic-serving-ca-secret-namespace=$(POD_NAMESPACE)",
                  "--dynamic-serving-ca-secret-name=cert-manager-webhook-ca",
                  "--dynamic-serving-dns-names=cert-manager-webhook,cert-manager-webhook.battery-core,cert-manager-webhook.battery-core.svc"
                ],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "fieldPath" => "metadata.namespace"
                      }
                    }
                  }
                ],
                "image" => "quay.io/jetstack/cert-manager-webhook:v1.8.0",
                "imagePullPolicy" => "IfNotPresent",
                "livenessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{
                    "path" => "/livez",
                    "port" => 6080,
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 60,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "name" => "cert-manager",
                "ports" => [
                  %{
                    "containerPort" => 10_250,
                    "name" => "https",
                    "protocol" => "TCP"
                  }
                ],
                "readinessProbe" => %{
                  "failureThreshold" => 3,
                  "httpGet" => %{
                    "path" => "/healthz",
                    "port" => 6080,
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 5,
                  "successThreshold" => 1,
                  "timeoutSeconds" => 1
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false
                }
              }
            ],
            "nodeSelector" => %{
              "kubernetes.io/os" => "linux"
            },
            "securityContext" => %{
              "runAsNonRoot" => true
            },
            "serviceAccountName" => "cert-manager-webhook"
          }
        }
      }
    }
  end

  def mutating_webhook_configuration(config) do
    namespace = SecuritySettings.namespace(config)

    webhooks = [
      %{
        "admissionReviewVersions" => [
          "v1"
        ],
        "clientConfig" => %{
          "service" => %{
            "name" => @webhook_service,
            "namespace" => namespace,
            "path" => "/mutate"
          }
        },
        "failurePolicy" => "Fail",
        "matchPolicy" => "Equivalent",
        "name" => "webhook.cert-manager.io",
        "rules" => [
          %{
            "apiGroups" => [
              "cert-manager.io",
              "acme.cert-manager.io"
            ],
            "apiVersions" => [
              "v1"
            ],
            "operations" => [
              "CREATE",
              "UPDATE"
            ],
            "resources" => [
              "*/*"
            ]
          }
        ],
        "sideEffects" => "None",
        "timeoutSeconds" => 10
      }
    ]

    B.build_resource(:mutating_webhook_config)
    |> B.name("battery-cert-manager-webhook")
    |> B.app_labels(@app)
    |> B.annotation(
      "cert-manager.io/inject-ca-from-secret",
      "battery-core/cert-manager-webhook-ca"
    )
    |> Map.put("webhooks", webhooks)
  end

  def validating_webhook_configuration(config) do
    namespace = SecuritySettings.namespace(config)

    webhooks = [
      %{
        "admissionReviewVersions" => [
          "v1"
        ],
        "clientConfig" => %{
          "service" => %{
            "name" => @webhook_service,
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
              "values" => [
                "true"
              ]
            },
            %{
              "key" => "name",
              "operator" => "NotIn",
              "values" => [
                "battery-core"
              ]
            }
          ]
        },
        "rules" => [
          %{
            "apiGroups" => [
              "cert-manager.io",
              "acme.cert-manager.io"
            ],
            "apiVersions" => [
              "v1"
            ],
            "operations" => [
              "CREATE",
              "UPDATE"
            ],
            "resources" => [
              "*/*"
            ]
          }
        ],
        "sideEffects" => "None",
        "timeoutSeconds" => 10
      }
    ]

    B.build_resource(:validating_webhook_config)
    |> B.name("battery-cert-manager-webhook")
    |> B.app_labels(@app)
    |> B.annotation(
      "cert-manager.io/inject-ca-from-secret",
      "battery-core/cert-manager-webhook-ca"
    )
    |> Map.put("webhooks", webhooks)
  end

  def service_account_3(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name(@cert_manager_startup_check_service_account)
    |> Map.put("automountServiceAccountToken", true)
  end

  def role_3(config) do
    namespace = SecuritySettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          "cert-manager.io"
        ],
        "resources" => [
          "certificates"
        ],
        "verbs" => [
          "create"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.app_labels(@app)
    |> B.name(@startup_role)
    |> B.namespace(namespace)
    |> B.rules(rules)
  end

  def role_binding_3(config) do
    namespace = SecuritySettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@startup_role)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_role_ref(@startup_role))
    |> B.subject(B.build_service_account(@cert_manager_startup_check_service_account, namespace))
  end

  def job(config) do
    namespace = SecuritySettings.namespace(config)

    spec = %{
      "backoffLimit" => 4,
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "app.kubernetes.io/component" => "startupapicheck",
            "app.kubernetes.io/instance" => "cert-manager",
            "battery/app" => "cert-manager",
            "battery/managed" => "true"
          },
          "annotations" => %{
            "sidecar.istio.io/inject" => "false"
          }
        },
        "spec" => %{
          "containers" => [
            %{
              "args" => [
                "check",
                "api",
                "--wait=1m"
              ],
              "image" => "quay.io/jetstack/cert-manager-ctl:v1.8.0",
              "imagePullPolicy" => "IfNotPresent",
              "name" => "cert-manager",
              "securityContext" => %{
                "allowPrivilegeEscalation" => false
              }
            }
          ],
          "restartPolicy" => "OnFailure",
          "securityContext" => %{
            "runAsNonRoot" => true
          },
          "serviceAccountName" => @cert_manager_startup_check_service_account
        }
      }
    }

    B.build_resource(:job)
    |> B.namespace(namespace)
    |> B.name("cert-manager-startupapicheck")
    |> B.app_labels(@app)
    |> B.spec(spec)
    |> B.annotation("sidecar.istio.io/inject", "false")
  end

  defp crd_content, do: unquote(File.read!(@crd_path))

  def crd(_config) do
    yaml(crd_content())
  end

  def materialize(config) do
    %{
      "/0/crd" => crd(config),
      "/0/service_account" => service_account(config),
      "/1/service_account_1" => service_account_1(config),
      "/2/service_account_2" => service_account_2(config),
      "/3/config_map" => config_map(config),
      "/4/cluster_role" => cluster_role(config),
      "/5/cluster_role_1" => cluster_role_1(config),
      "/6/cluster_role_2" => cluster_role_2(config),
      "/7/cluster_role_3" => cluster_role_3(config),
      "/8/cluster_role_4" => cluster_role_4(config),
      "/9/cluster_role_5" => cluster_role_5(config),
      "/10/cluster_role_6" => cluster_role_6(config),
      "/11/cluster_role_7" => cluster_role_7(config),
      "/12/cluster_role_8" => cluster_role_8(config),
      "/13/cluster_role_9" => cluster_role_9(config),
      "/14/cluster_role_10" => cluster_role_10(config),
      "/15/cluster_role_11" => cluster_role_11(config),
      "/16/cluster_role_binding" => cluster_role_binding(config),
      "/17/cluster_role_binding_1" => cluster_role_binding_1(config),
      "/18/cluster_role_binding_2" => cluster_role_binding_2(config),
      "/19/cluster_role_binding_3" => cluster_role_binding_3(config),
      "/20/cluster_role_binding_4" => cluster_role_binding_4(config),
      "/21/cluster_role_binding_5" => cluster_role_binding_5(config),
      "/22/cluster_role_binding_6" => cluster_role_binding_6(config),
      "/23/cluster_role_binding_7" => cluster_role_binding_7(config),
      "/24/cluster_role_binding_8" => cluster_role_binding_8(config),
      "/25/cluster_role_binding_9" => cluster_role_binding_9(config),
      "/26/role" => role(config),
      "/27/role_1" => role_1(config),
      "/28/role_2" => role_2(config),
      "/29/role_binding" => role_binding(config),
      "/30/role_binding_1" => role_binding_1(config),
      "/31/role_binding_2" => role_binding_2(config),
      "/32/service" => service(config),
      "/33/service_1" => service_1(config),
      "/34/deployment" => deployment(config),
      "/35/deployment_1" => deployment_1(config),
      "/36/deployment_2" => deployment_2(config),
      "/37/mutating_webhook_configuration" => mutating_webhook_configuration(config),
      "/38/validating_webhook_configuration" => validating_webhook_configuration(config),
      "/39/service_account_3" => service_account_3(config),
      "/40/role_3" => role_3(config),
      "/41/role_binding_3" => role_binding_3(config),
      "/42/job" => job(config)
    }
  end
end
