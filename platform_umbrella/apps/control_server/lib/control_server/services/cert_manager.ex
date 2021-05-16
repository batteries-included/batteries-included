defmodule ControlServer.Services.CertManager do
  @moduledoc false

  alias ControlServer.Settings.SecuritySettings

  def service_account_0(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "automountServiceAccountToken" => true,
      "metadata" => %{
        "name" => "battery-cert-manager-cainjector",
        "namespace" => namespace,
        "labels" => %{
          "app" => "cainjector",
          "app.kubernetes.io/name" => "cainjector",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cainjector",
          "battery-managed" => "True"
        }
      }
    }
  end

  def service_account_1(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "automountServiceAccountToken" => true,
      "metadata" => %{
        "name" => "battery-cert-manager",
        "namespace" => namespace,
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      }
    }
  end

  def service_account_2(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "automountServiceAccountToken" => true,
      "metadata" => %{
        "name" => "battery-cert-manager-webhook",
        "namespace" => namespace,
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        }
      }
    }
  end

  def cluster_role_0(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-cainjector",
        "labels" => %{
          "app" => "cainjector",
          "app.kubernetes.io/name" => "cainjector",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cainjector",
          "battery-managed" => "True"
        }
      },
      "rules" => [
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
        },
        %{
          "apiGroups" => ["auditregistration.k8s.io"],
          "resources" => ["auditsinks"],
          "verbs" => ["get", "list", "watch", "update"]
        }
      ]
    }
  end

  def cluster_role_1(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-issuers",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["cert-manager.io"],
          "resources" => ["issuers", "issuers/status"],
          "verbs" => ["update"]
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
    }
  end

  def cluster_role_2(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-clusterissuers",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["cert-manager.io"],
          "resources" => ["clusterissuers", "clusterissuers/status"],
          "verbs" => ["update"]
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
    }
  end

  def cluster_role_3(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-certificates",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["cert-manager.io"],
          "resources" => [
            "certificates",
            "certificates/status",
            "certificaterequests",
            "certificaterequests/status"
          ],
          "verbs" => ["update"]
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
          "verbs" => ["get", "list", "watch", "create", "update", "delete"]
        },
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
      ]
    }
  end

  def cluster_role_4(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-orders",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["acme.cert-manager.io"],
          "resources" => ["orders", "orders/status"],
          "verbs" => ["update"]
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
    }
  end

  def cluster_role_5(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-challenges",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["acme.cert-manager.io"],
          "resources" => ["challenges", "challenges/status"],
          "verbs" => ["update"]
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
    }
  end

  def cluster_role_6(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-ingress-shim",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "rules" => [
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
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]}
      ]
    }
  end

  def cluster_role_7(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-view",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "rbac.authorization.k8s.io/aggregate-to-view" => "true",
          "rbac.authorization.k8s.io/aggregate-to-edit" => "true",
          "rbac.authorization.k8s.io/aggregate-to-admin" => "true",
          "battery-managed" => "True"
        }
      },
      "rules" => [
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
    }
  end

  def cluster_role_8(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-edit",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "rbac.authorization.k8s.io/aggregate-to-edit" => "true",
          "rbac.authorization.k8s.io/aggregate-to-admin" => "true",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["cert-manager.io"],
          "resources" => ["certificates", "certificaterequests", "issuers"],
          "verbs" => ["create", "delete", "deletecollection", "patch", "update"]
        },
        %{
          "apiGroups" => ["acme.cert-manager.io"],
          "resources" => ["challenges", "orders"],
          "verbs" => ["create", "delete", "deletecollection", "patch", "update"]
        }
      ]
    }
  end

  def cluster_role_9(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-approve:cert-manager-io",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cert-manager",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["cert-manager.io"],
          "resources" => ["signers"],
          "verbs" => ["approve"],
          "resourceNames" => ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]
        }
      ]
    }
  end

  def cluster_role_10(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{
        "name" => "battery-cert-manager-webhook:subjectaccessreviews",
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => ["authorization.k8s.io"],
          "resources" => ["subjectaccessreviews"],
          "verbs" => ["create"]
        }
      ]
    }
  end

  def cluster_role_binding_0(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-cainjector",
        "labels" => %{
          "app" => "cainjector",
          "app.kubernetes.io/name" => "cainjector",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cainjector",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-cainjector"
      },
      "subjects" => [
        %{
          "name" => "battery-cert-manager-cainjector",
          "namespace" => namespace,
          "kind" => "ServiceAccount"
        }
      ]
    }
  end

  def cluster_role_binding_1(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-issuers",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-controller-issuers"
      },
      "subjects" => [
        %{"name" => "battery-cert-manager", "namespace" => namespace, "kind" => "ServiceAccount"}
      ]
    }
  end

  def cluster_role_binding_2(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-clusterissuers",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-controller-clusterissuers"
      },
      "subjects" => [
        %{"name" => "battery-cert-manager", "namespace" => namespace, "kind" => "ServiceAccount"}
      ]
    }
  end

  def cluster_role_binding_3(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-certificates",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-controller-certificates"
      },
      "subjects" => [
        %{"name" => "battery-cert-manager", "namespace" => namespace, "kind" => "ServiceAccount"}
      ]
    }
  end

  def cluster_role_binding_4(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-orders",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-controller-orders"
      },
      "subjects" => [
        %{"name" => "battery-cert-manager", "namespace" => namespace, "kind" => "ServiceAccount"}
      ]
    }
  end

  def cluster_role_binding_5(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-challenges",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-controller-challenges"
      },
      "subjects" => [
        %{"name" => "battery-cert-manager", "namespace" => namespace, "kind" => "ServiceAccount"}
      ]
    }
  end

  def cluster_role_binding_6(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-ingress-shim",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-controller-ingress-shim"
      },
      "subjects" => [
        %{"name" => "battery-cert-manager", "namespace" => namespace, "kind" => "ServiceAccount"}
      ]
    }
  end

  def cluster_role_binding_7(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-controller-approve:cert-manager-io",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cert-manager",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-controller-approve:cert-manager-io"
      },
      "subjects" => [
        %{"name" => "battery-cert-manager", "namespace" => namespace, "kind" => "ServiceAccount"}
      ]
    }
  end

  def cluster_role_binding_8(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-webhook:subjectaccessreviews",
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-cert-manager-webhook:subjectaccessreviews"
      },
      "subjects" => [
        %{
          "apiGroup" => "",
          "kind" => "ServiceAccount",
          "name" => "battery-cert-manager-webhook",
          "namespace" => namespace
        }
      ]
    }
  end

  def role_0(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => "battery-cert-manager-cainjector:leaderelection",
        "namespace" => "kube-system",
        "labels" => %{
          "app" => "cainjector",
          "app.kubernetes.io/name" => "cainjector",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cainjector",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "resourceNames" => [
            "cert-manager-cainjector-leader-election",
            "cert-manager-cainjector-leader-election-core"
          ],
          "verbs" => ["get", "update", "patch"]
        },
        %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["create"]}
      ]
    }
  end

  def role_1(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => "battery-cert-manager:leaderelection",
        "namespace" => "kube-system",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "resourceNames" => ["cert-manager-controller"],
          "verbs" => ["get", "update", "patch"]
        },
        %{"apiGroups" => [""], "resources" => ["configmaps"], "verbs" => ["create"]}
      ]
    }
  end

  def role_2(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => "battery-cert-manager-webhook:dynamic-serving",
        "namespace" => namespace,
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        }
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["secrets"],
          "resourceNames" => ["battery-cert-manager-webhook-ca"],
          "verbs" => ["get", "list", "watch", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["secrets"], "verbs" => ["create"]}
      ]
    }
  end

  def role_binding_0(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-cainjector:leaderelection",
        "namespace" => "kube-system",
        "labels" => %{
          "app" => "cainjector",
          "app.kubernetes.io/name" => "cainjector",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cainjector",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "battery-cert-manager-cainjector:leaderelection"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-cert-manager-cainjector",
          "namespace" => namespace
        }
      ]
    }
  end

  def role_binding_1(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager:leaderelection",
        "namespace" => "kube-system",
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "battery-cert-manager:leaderelection"
      },
      "subjects" => [
        %{
          "apiGroup" => "",
          "kind" => "ServiceAccount",
          "name" => "battery-cert-manager",
          "namespace" => namespace
        }
      ]
    }
  end

  def role_binding_2(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => "battery-cert-manager-webhook:dynamic-serving",
        "namespace" => namespace,
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        }
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "battery-cert-manager-webhook:dynamic-serving"
      },
      "subjects" => [
        %{
          "apiGroup" => "",
          "kind" => "ServiceAccount",
          "name" => "battery-cert-manager-webhook",
          "namespace" => namespace
        }
      ]
    }
  end

  def service_0(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => "battery-cert-manager",
        "namespace" => namespace,
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "spec" => %{
        "type" => "ClusterIP",
        "ports" => [%{"protocol" => "TCP", "port" => 9402, "targetPort" => 9402}],
        "selector" => %{
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller"
        }
      }
    }
  end

  def service_1(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => "battery-cert-manager-webhook",
        "namespace" => namespace,
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        }
      },
      "spec" => %{
        "type" => "ClusterIP",
        "ports" => [%{"name" => "https", "port" => 443, "targetPort" => 10_250}],
        "selector" => %{
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook"
        }
      }
    }
  end

  def deployment_0(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => "battery-cert-manager-cainjector",
        "namespace" => namespace,
        "labels" => %{
          "app" => "cainjector",
          "app.kubernetes.io/name" => "cainjector",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "cainjector",
          "battery-managed" => "True"
        }
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/name" => "cainjector",
            "app.kubernetes.io/instance" => "battery-cert-manager",
            "app.kubernetes.io/component" => "cainjector"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app" => "cainjector",
              "app.kubernetes.io/name" => "cainjector",
              "app.kubernetes.io/instance" => "battery-cert-manager",
              "app.kubernetes.io/component" => "cainjector",
              "battery-managed" => "True"
            }
          },
          "spec" => %{
            "serviceAccountName" => "battery-cert-manager-cainjector",
            "containers" => [
              %{
                "name" => "cert-manager",
                "image" => "quay.io/jetstack/cert-manager-cainjector:v1.3.1",
                "imagePullPolicy" => "IfNotPresent",
                "args" => ["--v=2", "--leader-election-namespace=kube-system"],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  }
                ],
                "resources" => %{}
              }
            ]
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
        "name" => "battery-cert-manager",
        "namespace" => namespace,
        "labels" => %{
          "app" => "cert-manager",
          "app.kubernetes.io/name" => "cert-manager",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "controller",
          "battery-managed" => "True"
        }
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/name" => "cert-manager",
            "app.kubernetes.io/instance" => "battery-cert-manager",
            "app.kubernetes.io/component" => "controller"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app" => "cert-manager",
              "app.kubernetes.io/name" => "cert-manager",
              "app.kubernetes.io/instance" => "battery-cert-manager",
              "app.kubernetes.io/component" => "controller",
              "battery-managed" => "True"
            },
            "annotations" => %{
              "prometheus.io/path" => "/metrics",
              "prometheus.io/scrape" => "true",
              "prometheus.io/port" => "9402"
            }
          },
          "spec" => %{
            "serviceAccountName" => "battery-cert-manager",
            "containers" => [
              %{
                "name" => "cert-manager",
                "image" => "quay.io/jetstack/cert-manager-controller:v1.3.1",
                "imagePullPolicy" => "IfNotPresent",
                "args" => [
                  "--v=2",
                  "--cluster-resource-namespace=$(POD_NAMESPACE)",
                  "--leader-election-namespace=kube-system"
                ],
                "ports" => [%{"containerPort" => 9402, "protocol" => "TCP"}],
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  }
                ],
                "resources" => %{}
              }
            ]
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
        "name" => "battery-cert-manager-webhook",
        "namespace" => namespace,
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        }
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/name" => "webhook",
            "app.kubernetes.io/instance" => "battery-cert-manager",
            "app.kubernetes.io/component" => "webhook"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app" => "webhook",
              "app.kubernetes.io/name" => "webhook",
              "app.kubernetes.io/instance" => "battery-cert-manager",
              "app.kubernetes.io/component" => "webhook",
              "battery-managed" => "True"
            }
          },
          "spec" => %{
            "serviceAccountName" => "battery-cert-manager-webhook",
            "containers" => [
              %{
                "name" => "cert-manager",
                "image" => "quay.io/jetstack/cert-manager-webhook:v1.3.1",
                "imagePullPolicy" => "IfNotPresent",
                "args" => [
                  "--v=2",
                  "--secure-port=10250",
                  "--dynamic-serving-ca-secret-namespace=$(POD_NAMESPACE)",
                  "--dynamic-serving-ca-secret-name=battery-cert-manager-webhook-ca",
                  "--dynamic-serving-dns-names=battery-cert-manager-webhook,battery-cert-manager-webhook.battery-security,battery-cert-manager-webhook.battery-security.svc"
                ],
                "ports" => [%{"name" => "https", "containerPort" => 10_250}],
                "livenessProbe" => %{
                  "httpGet" => %{"path" => "/livez", "port" => 6080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 60,
                  "periodSeconds" => 10,
                  "timeoutSeconds" => 1,
                  "successThreshold" => 1,
                  "failureThreshold" => 3
                },
                "readinessProbe" => %{
                  "httpGet" => %{"path" => "/healthz", "port" => 6080, "scheme" => "HTTP"},
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 5,
                  "timeoutSeconds" => 1,
                  "successThreshold" => 1,
                  "failureThreshold" => 3
                },
                "env" => [
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  }
                ],
                "resources" => %{}
              }
            ]
          }
        }
      }
    }
  end

  def mutating_webhook_configuration_0(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1",
      "kind" => "MutatingWebhookConfiguration",
      "metadata" => %{
        "name" => "battery-cert-manager-webhook",
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        },
        "annotations" => %{
          "cert-manager.io/inject-ca-from-secret" =>
            "battery-security/battery-cert-manager-webhook-ca"
        }
      },
      "webhooks" => [
        %{
          "name" => "webhook.cert-manager.io",
          "rules" => [
            %{
              "apiGroups" => ["cert-manager.io", "acme.cert-manager.io"],
              "apiVersions" => ["*"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["*/*"]
            }
          ],
          "admissionReviewVersions" => ["v1", "v1beta1"],
          "timeoutSeconds" => 10,
          "failurePolicy" => "Fail",
          "sideEffects" => "None",
          "clientConfig" => %{
            "service" => %{
              "name" => "battery-cert-manager-webhook",
              "namespace" => namespace,
              "path" => "/mutate"
            }
          }
        }
      ]
    }
  end

  def validating_webhook_configuration_0(config) do
    namespace = SecuritySettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1",
      "kind" => "ValidatingWebhookConfiguration",
      "metadata" => %{
        "name" => "battery-cert-manager-webhook",
        "labels" => %{
          "app" => "webhook",
          "app.kubernetes.io/name" => "webhook",
          "app.kubernetes.io/instance" => "battery-cert-manager",
          "app.kubernetes.io/component" => "webhook",
          "battery-managed" => "True"
        },
        "annotations" => %{
          "cert-manager.io/inject-ca-from-secret" =>
            "battery-security/battery-cert-manager-webhook-ca"
        }
      },
      "webhooks" => [
        %{
          "name" => "webhook.cert-manager.io",
          "namespaceSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "cert-manager.io/disable-validation",
                "operator" => "NotIn",
                "values" => ["true"]
              },
              %{"key" => "name", "operator" => "NotIn", "values" => ["battery-security"]}
            ]
          },
          "rules" => [
            %{
              "apiGroups" => ["cert-manager.io", "acme.cert-manager.io"],
              "apiVersions" => ["*"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["*/*"]
            }
          ],
          "admissionReviewVersions" => ["v1", "v1beta1"],
          "timeoutSeconds" => 10,
          "failurePolicy" => "Fail",
          "sideEffects" => "None",
          "clientConfig" => %{
            "service" => %{
              "name" => "battery-cert-manager-webhook",
              "namespace" => namespace,
              "path" => "/validate"
            }
          }
        }
      ]
    }
  end

  def materialize(config) do
    %{
      "/0/service_account_0" => service_account_0(config),
      "/1/service_account_1" => service_account_1(config),
      "/2/service_account_2" => service_account_2(config),
      "/3/cluster_role_0" => cluster_role_0(config),
      "/4/cluster_role_1" => cluster_role_1(config),
      "/5/cluster_role_2" => cluster_role_2(config),
      "/6/cluster_role_3" => cluster_role_3(config),
      "/7/cluster_role_4" => cluster_role_4(config),
      "/8/cluster_role_5" => cluster_role_5(config),
      "/9/cluster_role_6" => cluster_role_6(config),
      "/10/cluster_role_7" => cluster_role_7(config),
      "/11/cluster_role_8" => cluster_role_8(config),
      "/12/cluster_role_9" => cluster_role_9(config),
      "/13/cluster_role_10" => cluster_role_10(config),
      "/14/cluster_role_binding_0" => cluster_role_binding_0(config),
      "/15/cluster_role_binding_1" => cluster_role_binding_1(config),
      "/16/cluster_role_binding_2" => cluster_role_binding_2(config),
      "/17/cluster_role_binding_3" => cluster_role_binding_3(config),
      "/18/cluster_role_binding_4" => cluster_role_binding_4(config),
      "/19/cluster_role_binding_5" => cluster_role_binding_5(config),
      "/20/cluster_role_binding_6" => cluster_role_binding_6(config),
      "/21/cluster_role_binding_7" => cluster_role_binding_7(config),
      "/22/cluster_role_binding_8" => cluster_role_binding_8(config),
      "/23/role_0" => role_0(config),
      "/24/role_1" => role_1(config),
      "/25/role_2" => role_2(config),
      "/26/role_binding_0" => role_binding_0(config),
      "/27/role_binding_1" => role_binding_1(config),
      "/28/role_binding_2" => role_binding_2(config),
      "/29/service_0" => service_0(config),
      "/30/service_1" => service_1(config),
      "/31/deployment_0" => deployment_0(config),
      "/32/deployment_1" => deployment_1(config),
      "/33/deployment_2" => deployment_2(config),
      "/34/mutating_webhook_configuration_0" => mutating_webhook_configuration_0(config),
      "/35/validating_webhook_configuration_0" => validating_webhook_configuration_0(config)
    }
  end
end
