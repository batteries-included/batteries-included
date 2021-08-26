defmodule KubeResources.GithubActionsRunner do
  @moduledoc false

  alias KubeResources.DevtoolsSettings

  def service_account_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-actions-runner-controller",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "actions-runner-controller",
          "battery/managed" => "True"
        }
      }
    }
  end

  def secret_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Secret",
      "metadata" => %{
        "name" => "controller-manager",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "actions-runner-controller",
          "battery/managed" => "True"
        }
      },
      "type" => "generic",
      "data" => %{
        "github_app_id" => Base.encode64(DevtoolsSettings.gh_app_id(config)),
        "github_app_installation_id" => Base.encode64(DevtoolsSettings.gh_install_id(config)),
        "github_app_private_key" => Base.encode64(DevtoolsSettings.gh_private_key(config))
      }
    }
  end

  def cluster_role_0(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => "battery-actions-runner-controller-proxy"},
      "rules" => [
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

  def cluster_role_1(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => "battery-actions-runner-controller-manager"},
      "rules" => [
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["horizontalrunnerautoscalers"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["horizontalrunnerautoscalers/finalizers"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["horizontalrunnerautoscalers/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runnerdeployments"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runnerdeployments/finalizers"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runnerdeployments/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runnerreplicasets"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runnerreplicasets/finalizers"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runnerreplicasets/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runners"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runners/finalizers"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runners/status"],
          "verbs" => ["get", "patch", "update"]
        },
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create", "patch"]},
        %{
          "apiGroups" => [""],
          "resources" => ["pods"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["pods/finalizers"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        }
      ]
    }
  end

  def cluster_role_2(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => "battery-actions-runner-controller-runner-editor"},
      "rules" => [
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runners"],
          "verbs" => ["create", "delete", "get", "list", "patch", "update", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runners/status"],
          "verbs" => ["get", "patch", "update"]
        }
      ]
    }
  end

  def cluster_role_3(_config) do
    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRole",
      "metadata" => %{"name" => "battery-actions-runner-controller-runner-viewer"},
      "rules" => [
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runners"],
          "verbs" => ["get", "list", "watch"]
        },
        %{
          "apiGroups" => ["actions.summerwind.dev"],
          "resources" => ["runners/status"],
          "verbs" => ["get"]
        }
      ]
    }
  end

  def cluster_role_binding_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{"name" => "battery-actions-runner-controller-proxy"},
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-actions-runner-controller-proxy"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-actions-runner-controller",
          "namespace" => namespace
        }
      ]
    }
  end

  def cluster_role_binding_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "ClusterRoleBinding",
      "metadata" => %{"name" => "battery-actions-runner-controller-manager"},
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "ClusterRole",
        "name" => "battery-actions-runner-controller-manager"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-actions-runner-controller",
          "namespace" => namespace
        }
      ]
    }
  end

  def role_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => "battery-actions-runner-controller-leader-election",
        "namespace" => namespace
      },
      "rules" => [
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps"],
          "verbs" => ["get", "list", "watch", "create", "update", "patch", "delete"]
        },
        %{
          "apiGroups" => [""],
          "resources" => ["configmaps/status"],
          "verbs" => ["get", "update", "patch"]
        },
        %{"apiGroups" => [""], "resources" => ["events"], "verbs" => ["create"]}
      ]
    }
  end

  def role_binding_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => "battery-actions-runner-controller-leader-election",
        "namespace" => namespace
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "battery-actions-runner-controller-leader-election"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-actions-runner-controller",
          "namespace" => namespace
        }
      ]
    }
  end

  def service_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "actions-runner-controller",
          "battery/managed" => "True"
        },
        "name" => "actions-runner-controller-metrics-service",
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [%{"name" => "https", "port" => 8443, "targetPort" => "https"}],
        "selector" => %{
          "battery/app" => "actions-runner-controller"
        }
      }
    }
  end

  def service_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "name" => "actions-runner-controller-webhook",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "actions-runner-controller",
          "battery/managed" => "True"
        }
      },
      "spec" => %{
        "type" => "ClusterIP",
        "ports" => [
          %{"port" => 443, "targetPort" => 9443, "protocol" => "TCP", "name" => "https"}
        ],
        "selector" => %{
          "battery/app" => "actions-runner-controller"
        }
      }
    }
  end

  def deployment_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => "actions-runner-controller",
        "namespace" => namespace,
        "labels" => %{
          "battery/app" => "actions-runner-controller",
          "battery/managed" => "True"
        }
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "battery/app" => "actions-runner-controller"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "battery/app" => "actions-runner-controller",
              "battery/managed" => "True"
            }
          },
          "spec" => %{
            "serviceAccountName" => "battery-actions-runner-controller",
            "securityContext" => %{},
            "containers" => [
              %{
                "args" => [
                  "--metrics-addr=127.0.0.1:8080",
                  "--enable-leader-election",
                  "--sync-period=10m",
                  "--docker-image=docker:dind"
                ],
                "command" => ["/manager"],
                "env" => [
                  %{
                    "name" => "GITHUB_TOKEN",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "github_token",
                        "name" => "controller-manager",
                        "optional" => true
                      }
                    }
                  },
                  %{
                    "name" => "GITHUB_APP_ID",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "github_app_id",
                        "name" => "controller-manager",
                        "optional" => true
                      }
                    }
                  },
                  %{
                    "name" => "GITHUB_APP_INSTALLATION_ID",
                    "valueFrom" => %{
                      "secretKeyRef" => %{
                        "key" => "github_app_installation_id",
                        "name" => "controller-manager",
                        "optional" => true
                      }
                    }
                  },
                  %{
                    "name" => "GITHUB_APP_PRIVATE_KEY",
                    "value" => "/etc/actions-runner-controller/github_app_private_key"
                  }
                ],
                "image" => "summerwind/actions-runner-controller:v0.18.2",
                "name" => "manager",
                "imagePullPolicy" => "IfNotPresent",
                "ports" => [
                  %{"containerPort" => 9443, "name" => "webhook-server", "protocol" => "TCP"}
                ],
                "resources" => %{},
                "securityContext" => %{},
                "volumeMounts" => [
                  %{
                    "mountPath" => "/etc/actions-runner-controller",
                    "name" => "secret",
                    "readOnly" => true
                  },
                  %{"mountPath" => "/tmp", "name" => "tmp"},
                  %{
                    "mountPath" => "/tmp/k8s-webhook-server/serving-certs",
                    "name" => "cert",
                    "readOnly" => true
                  }
                ]
              },
              KubeResources.RBAC.proxy_container("http://127.0.0.1:8080/", 8443, "https")
            ],
            "terminationGracePeriodSeconds" => 10,
            "volumes" => [
              %{"name" => "secret", "secret" => %{"secretName" => "controller-manager"}},
              %{
                "name" => "cert",
                "secret" => %{"defaultMode" => 420, "secretName" => "webhook-server-cert"}
              },
              %{"name" => "tmp", "emptyDir" => %{}}
            ]
          }
        }
      }
    }
  end

  def certificate_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "cert-manager.io/v1",
      "kind" => "Certificate",
      "metadata" => %{
        "name" => "actions-runner-controller-serving-cert",
        "namespace" => namespace
      },
      "spec" => %{
        "dnsNames" => [
          "actions-runner-controller-webhook.battery-core.svc",
          "actions-runner-controller-webhook.battery-core.svc.cluster.local"
        ],
        "issuerRef" => %{
          "kind" => "Issuer",
          "name" => "actions-runner-controller-selfsigned-issuer"
        },
        "secretName" => "webhook-server-cert"
      }
    }
  end

  def issuer_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "cert-manager.io/v1",
      "kind" => "Issuer",
      "metadata" => %{
        "name" => "actions-runner-controller-selfsigned-issuer",
        "namespace" => namespace
      },
      "spec" => %{"selfSigned" => %{}}
    }
  end

  def mutating_webhook_configuration_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1beta1",
      "kind" => "MutatingWebhookConfiguration",
      "metadata" => %{
        "name" => "battery-actions-runner-controller-mutating-webhook-configuration",
        "annotations" => %{
          "cert-manager.io/inject-ca-from" =>
            "battery-core/actions-runner-controller-serving-cert"
        }
      },
      "webhooks" => [
        %{
          "clientConfig" => %{
            "caBundle" => "Cg==",
            "service" => %{
              "name" => "actions-runner-controller-webhook",
              "namespace" => namespace,
              "path" => "/mutate-actions-summerwind-dev-v1alpha1-runner"
            }
          },
          "failurePolicy" => "Fail",
          "name" => "mutate.runner.actions.summerwind.dev",
          "rules" => [
            %{
              "apiGroups" => ["actions.summerwind.dev"],
              "apiVersions" => ["v1alpha1"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["runners"]
            }
          ]
        },
        %{
          "clientConfig" => %{
            "caBundle" => "Cg==",
            "service" => %{
              "name" => "actions-runner-controller-webhook",
              "namespace" => namespace,
              "path" => "/mutate-actions-summerwind-dev-v1alpha1-runnerdeployment"
            }
          },
          "failurePolicy" => "Fail",
          "name" => "mutate.runnerdeployment.actions.summerwind.dev",
          "rules" => [
            %{
              "apiGroups" => ["actions.summerwind.dev"],
              "apiVersions" => ["v1alpha1"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["runnerdeployments"]
            }
          ]
        },
        %{
          "clientConfig" => %{
            "caBundle" => "Cg==",
            "service" => %{
              "name" => "actions-runner-controller-webhook",
              "namespace" => namespace,
              "path" => "/mutate-actions-summerwind-dev-v1alpha1-runnerreplicaset"
            }
          },
          "failurePolicy" => "Fail",
          "name" => "mutate.runnerreplicaset.actions.summerwind.dev",
          "rules" => [
            %{
              "apiGroups" => ["actions.summerwind.dev"],
              "apiVersions" => ["v1alpha1"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["runnerreplicasets"]
            }
          ]
        }
      ]
    }
  end

  def validating_webhook_configuration_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1beta1",
      "kind" => "ValidatingWebhookConfiguration",
      "metadata" => %{
        "name" => "battery-actions-runner-controller-validating-webhook-configuration",
        "annotations" => %{
          "cert-manager.io/inject-ca-from" =>
            "battery-core/actions-runner-controller-serving-cert"
        }
      },
      "webhooks" => [
        %{
          "clientConfig" => %{
            "caBundle" => "Cg==",
            "service" => %{
              "name" => "actions-runner-controller-webhook",
              "namespace" => namespace,
              "path" => "/validate-actions-summerwind-dev-v1alpha1-runner"
            }
          },
          "failurePolicy" => "Fail",
          "name" => "validate.runner.actions.summerwind.dev",
          "rules" => [
            %{
              "apiGroups" => ["actions.summerwind.dev"],
              "apiVersions" => ["v1alpha1"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["runners"]
            }
          ]
        },
        %{
          "clientConfig" => %{
            "caBundle" => "Cg==",
            "service" => %{
              "name" => "actions-runner-controller-webhook",
              "namespace" => namespace,
              "path" => "/validate-actions-summerwind-dev-v1alpha1-runnerdeployment"
            }
          },
          "failurePolicy" => "Fail",
          "name" => "validate.runnerdeployment.actions.summerwind.dev",
          "rules" => [
            %{
              "apiGroups" => ["actions.summerwind.dev"],
              "apiVersions" => ["v1alpha1"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["runnerdeployments"]
            }
          ]
        },
        %{
          "clientConfig" => %{
            "caBundle" => "Cg==",
            "service" => %{
              "name" => "actions-runner-controller-webhook",
              "namespace" => namespace,
              "path" => "/validate-actions-summerwind-dev-v1alpha1-runnerreplicaset"
            }
          },
          "failurePolicy" => "Fail",
          "name" => "validate.runnerreplicaset.actions.summerwind.dev",
          "rules" => [
            %{
              "apiGroups" => ["actions.summerwind.dev"],
              "apiVersions" => ["v1alpha1"],
              "operations" => ["CREATE", "UPDATE"],
              "resources" => ["runnerreplicasets"]
            }
          ]
        }
      ]
    }
  end

  def materialize(config) do
    %{
      "/0/service_account_0" => service_account_0(config),
      "/1/secret_0" => secret_0(config),
      "/2/cluster_role_0" => cluster_role_0(config),
      "/3/cluster_role_1" => cluster_role_1(config),
      "/4/cluster_role_2" => cluster_role_2(config),
      "/5/cluster_role_3" => cluster_role_3(config),
      "/6/cluster_role_binding_0" => cluster_role_binding_0(config),
      "/7/cluster_role_binding_1" => cluster_role_binding_1(config),
      "/8/role_0" => role_0(config),
      "/9/role_binding_0" => role_binding_0(config),
      "/10/service_0" => service_0(config),
      "/11/service_1" => service_1(config),
      "/12/deployment_0" => deployment_0(config),
      "/13/certificate_0" => certificate_0(config),
      "/14/issuer_0" => issuer_0(config),
      "/15/mutating_webhook_configuration_0" => mutating_webhook_configuration_0(config),
      "/16/validating_webhook_configuration_0" => validating_webhook_configuration_0(config)
    }
  end
end
