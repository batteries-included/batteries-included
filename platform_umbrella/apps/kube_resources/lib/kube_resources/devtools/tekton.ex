defmodule KubeResources.Tekton do
  @moduledoc false

  use KubeExt.IncludeResource, crd: "priv/manifests/tekton/crds.yaml"

  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeResources.DevtoolsSettings

  @app "tekton-pipelines"

  @controller_service_account_name "tekton-controller"
  @webhook_service_account_name "tekton-webhook"

  @pod_security_policy_name "battery-tekton-pipelines"
  @controller_cluster_access_cluster_role_name "battery-tekton-controller-cluster-access"
  @webhook_cluster_access_cluster_role_name "battery-tekton-webhook-cluster-access"
  @controller_tenant_access_cluster_role_name "battery-tekton-controller-tenant-access"
  @aggregate_edit_cluster_role_name "battery-tekton-aggregate-edit"
  @aggregate_view_cluster_role_name "battery-tekton-aggregate-view"

  @controller_role_name "tekton-controller"
  @webhook_role_name "tekton-webhook"
  @leader_election_role_name "tekton-leader-election"
  @info_role_name "tekton-info"

  @webhook_certs_secret_name "tekton-webhook-certs"

  @artifact_bucket_config_name "tekton-config-artifact-bucket"
  @artifact_pvc_config_name "tekton-config-artifact-pvc"

  @defaults_config_name "tekton-config-defaults"
  @feature_flags_config_name "tekton-config-feature-flags"
  @info_config_name "tekton-config-info"
  @leader_election_config_name "tekton-config-leader-election"
  @logging_config_name "tekton-config-logging"
  @observability_config_name "tekton-config-observability"
  @registry_cert_config_name "tekton-config-registry-cert"

  @webhook_service_name "tekton-pipelines-webhook"
  @controller_service_name "tekton-controller"

  def pod_security_policy(_config) do
    spec = %{
      "allowPrivilegeEscalation" => false,
      "fsGroup" => %{
        "ranges" => [
          %{
            "max" => 65_535,
            "min" => 1
          }
        ],
        "rule" => "MustRunAs"
      },
      "hostIPC" => false,
      "hostNetwork" => false,
      "hostPID" => false,
      "privileged" => false,
      "requiredDropCapabilities" => [
        "ALL"
      ],
      "runAsGroup" => %{
        "ranges" => [
          %{
            "max" => 65_535,
            "min" => 1
          }
        ],
        "rule" => "MustRunAs"
      },
      "runAsUser" => %{
        "rule" => "MustRunAsNonRoot"
      },
      "seLinux" => %{
        "rule" => "RunAsAny"
      },
      "supplementalGroups" => %{
        "ranges" => [
          %{
            "max" => 65_535,
            "min" => 1
          }
        ],
        "rule" => "MustRunAs"
      },
      "volumes" => [
        "emptyDir",
        "configMap",
        "secret"
      ]
    }

    annotations = %{
      "apparmor.security.beta.kubernetes.io/allowedProfileNames" => "runtime/default",
      "apparmor.security.beta.kubernetes.io/defaultProfileName" => "runtime/default",
      "seccomp.security.alpha.kubernetes.io/allowedProfileNames" =>
        "docker/default,runtime/default",
      "seccomp.security.alpha.kubernetes.io/defaultProfileName" => "runtime/default"
    }

    B.build_resource(:pod_security_policy)
    |> B.name(@pod_security_policy_name)
    |> B.app_labels(@app)
    |> B.spec(spec)
    |> B.annotations(annotations)
  end

  def cluster_role(_config) do
    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "pods"
        ],
        "verbs" => [
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "tasks",
          "clustertasks",
          "taskruns",
          "pipelines",
          "pipelineruns",
          "pipelineresources",
          "conditions",
          "runs"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "taskruns/finalizers",
          "pipelineruns/finalizers",
          "runs/finalizers"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "tasks/status",
          "clustertasks/status",
          "taskruns/status",
          "pipelines/status",
          "pipelineruns/status",
          "pipelineresources/status",
          "runs/status"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@controller_cluster_access_cluster_role_name)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def cluster_role_1(_config) do
    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "pods",
          "persistentvolumeclaims"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
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
          "update",
          "patch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps",
          "limitranges",
          "secrets",
          "serviceaccounts"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "apps"
        ],
        "resources" => [
          "statefulsets"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "resolution.tekton.dev"
        ],
        "resources" => [
          "resolutionrequests"
        ],
        "verbs" => [
          "get",
          "list",
          "watch",
          "create",
          "delete"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@controller_tenant_access_cluster_role_name)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def cluster_role_2(config) do
    namespace = DevtoolsSettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          "apiextensions.k8s.io"
        ],
        "resourceNames" => [
          "pipelines.tekton.dev",
          "pipelineruns.tekton.dev",
          "runs.tekton.dev",
          "tasks.tekton.dev",
          "clustertasks.tekton.dev",
          "taskruns.tekton.dev",
          "pipelineresources.tekton.dev",
          "conditions.tekton.dev"
        ],
        "resources" => [
          "customresourcedefinitions",
          "customresourcedefinitions/status"
        ],
        "verbs" => [
          "get",
          "update",
          "patch"
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
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "admissionregistration.k8s.io"
        ],
        "resources" => [
          "mutatingwebhookconfigurations",
          "validatingwebhookconfigurations"
        ],
        "verbs" => [
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          "admissionregistration.k8s.io"
        ],
        "resourceNames" => [
          "webhook.pipeline.tekton.dev"
        ],
        "resources" => [
          "mutatingwebhookconfigurations"
        ],
        "verbs" => [
          "get",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "admissionregistration.k8s.io"
        ],
        "resourceNames" => [
          "validation.webhook.pipeline.tekton.dev",
          "config.webhook.pipeline.tekton.dev"
        ],
        "resources" => [
          "validatingwebhookconfigurations"
        ],
        "verbs" => [
          "get",
          "update",
          "delete"
        ]
      },
      %{
        "apiGroups" => [
          "policy"
        ],
        "resourceNames" => [
          @pod_security_policy_name
        ],
        "resources" => [
          "podsecuritypolicies"
        ],
        "verbs" => [
          "use"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          namespace
        ],
        "resources" => [
          "namespaces"
        ],
        "verbs" => [
          "get"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          namespace
        ],
        "resources" => [
          "namespaces/finalizers"
        ],
        "verbs" => [
          "update"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@webhook_cluster_access_cluster_role_name)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def cluster_role_3(_config) do
    rules = [
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "tasks",
          "taskruns",
          "pipelines",
          "pipelineruns",
          "pipelineresources",
          "conditions"
        ],
        "verbs" => [
          "create",
          "delete",
          "deletecollection",
          "get",
          "list",
          "patch",
          "update",
          "watch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@aggregate_edit_cluster_role_name)
    |> B.app_labels(@app)
    |> B.rules(rules)
    |> B.label("rbac.authorization.k8s.io/aggregate-to-admin", "true")
    |> B.label("rbac.authorization.k8s.io/aggregate-to-edit", "true")
  end

  def cluster_role_4(_config) do
    rules = [
      %{
        "apiGroups" => [
          "tekton.dev"
        ],
        "resources" => [
          "tasks",
          "taskruns",
          "pipelines",
          "pipelineruns",
          "pipelineresources",
          "conditions"
        ],
        "verbs" => [
          "get",
          "list",
          "watch"
        ]
      }
    ]

    B.build_resource(:cluster_role)
    |> B.name(@aggregate_view_cluster_role_name)
    |> B.app_labels(@app)
    |> B.rules(rules)
    |> B.label("rbac.authorization.k8s.io/aggregate-to-view", "true")
  end

  def role(config) do
    namespace = DevtoolsSettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @logging_config_name,
          @observability_config_name,
          @artifact_bucket_config_name,
          @artifact_pvc_config_name,
          @feature_flags_config_name,
          @leader_election_config_name,
          @registry_cert_config_name
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "get"
        ]
      },
      %{
        "apiGroups" => [
          "policy"
        ],
        "resourceNames" => [
          @pod_security_policy_name
        ],
        "resources" => [
          "podsecuritypolicies"
        ],
        "verbs" => [
          "use"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.name(@controller_role_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def role_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @feature_flags_config_name,
          @leader_election_config_name,
          @logging_config_name,
          @observability_config_name
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "get"
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
          "list",
          "watch"
        ]
      },
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @webhook_certs_secret_name
        ],
        "resources" => [
          "secrets"
        ],
        "verbs" => [
          "get",
          "update"
        ]
      },
      %{
        "apiGroups" => [
          "policy"
        ],
        "resourceNames" => [
          @pod_security_policy_name
        ],
        "resources" => [
          "podsecuritypolicies"
        ],
        "verbs" => [
          "use"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.name(@webhook_role_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def role_2(config) do
    namespace = DevtoolsSettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          "coordination.k8s.io"
        ],
        "resources" => [
          "leases"
        ],
        "verbs" => [
          "get",
          "list",
          "create",
          "update",
          "delete",
          "patch",
          "watch"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.name(@leader_election_role_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def role_3(config) do
    namespace = DevtoolsSettings.namespace(config)

    rules = [
      %{
        "apiGroups" => [
          ""
        ],
        "resourceNames" => [
          @info_config_name
        ],
        "resources" => [
          "configmaps"
        ],
        "verbs" => [
          "get"
        ]
      }
    ]

    B.build_resource(:role)
    |> B.name(@info_role_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.rules(rules)
  end

  def service_account(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name(@controller_service_account_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def service_account_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:service_account)
    |> B.name(@webhook_service_account_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def cluster_role_binding(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@controller_cluster_access_cluster_role_name)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@controller_cluster_access_cluster_role_name))
    |> B.subject(B.build_service_account(@controller_service_account_name, namespace))
  end

  def cluster_role_binding_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@controller_tenant_access_cluster_role_name)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@controller_tenant_access_cluster_role_name))
    |> B.subject(B.build_service_account(@controller_service_account_name, namespace))
  end

  def cluster_role_binding_2(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name(@webhook_cluster_access_cluster_role_name)
    |> B.app_labels(@app)
    |> B.role_ref(B.build_cluster_role_ref(@webhook_cluster_access_cluster_role_name))
    |> B.subject(B.build_service_account(@webhook_service_account_name, namespace))
  end

  def role_binding(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@controller_service_account_name)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@controller_role_name))
    |> B.subject(B.build_service_account(@controller_service_account_name, namespace))
  end

  def role_binding_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name(@webhook_service_account_name)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@webhook_role_name))
    |> B.subject(B.build_service_account(@webhook_service_account_name, namespace))
  end

  def role_binding_2(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name("tekton-controller-leader-election")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@leader_election_role_name))
    |> B.subject(B.build_service_account(@controller_service_account_name, namespace))
  end

  def role_binding_3(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name("tekton-webhook-leader-election")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@leader_election_role_name))
    |> B.subject(B.build_service_account(@webhook_service_account_name, namespace))
  end

  def role_binding_4(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:role_binding)
    |> B.name("tekton-info")
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.role_ref(B.build_role_ref(@info_role_name))
    |> B.subject(%{
      "apiGroup" => "rbac.authorization.k8s.io",
      "kind" => "Group",
      "name" => "system:authenticated"
    })
  end

  def secret(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:secret)
    |> B.name(@webhook_certs_secret_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def validating_webhook_configuration(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1",
      "kind" => "ValidatingWebhookConfiguration",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "webhook",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-pipelines",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0"
        },
        "name" => "validation.webhook.pipeline.tekton.dev"
      },
      "webhooks" => [
        %{
          "admissionReviewVersions" => [
            "v1"
          ],
          "clientConfig" => %{
            "service" => %{
              "name" => @webhook_service_name,
              "namespace" => namespace
            }
          },
          "failurePolicy" => "Fail",
          "name" => "validation.webhook.pipeline.tekton.dev",
          "sideEffects" => "None"
        }
      ]
    }
  end

  def mutating_webhook_configuration(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1",
      "kind" => "MutatingWebhookConfiguration",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "webhook",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-pipelines",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0"
        },
        "name" => "webhook.pipeline.tekton.dev"
      },
      "webhooks" => [
        %{
          "admissionReviewVersions" => [
            "v1"
          ],
          "clientConfig" => %{
            "service" => %{
              "name" => @webhook_service_name,
              "namespace" => namespace
            }
          },
          "failurePolicy" => "Fail",
          "name" => "webhook.pipeline.tekton.dev",
          "sideEffects" => "None"
        }
      ]
    }
  end

  def validating_webhook_configuration_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1",
      "kind" => "ValidatingWebhookConfiguration",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "webhook",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-pipelines",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0"
        },
        "name" => "config.webhook.pipeline.tekton.dev"
      },
      "webhooks" => [
        %{
          "admissionReviewVersions" => [
            "v1"
          ],
          "clientConfig" => %{
            "service" => %{
              "name" => @webhook_service_name,
              "namespace" => namespace
            }
          },
          "failurePolicy" => "Fail",
          "name" => "config.webhook.pipeline.tekton.dev",
          "objectSelector" => %{
            "matchLabels" => %{
              "battery/app" => "tekton-pipelines",
              "battery/managed" => "true"
            }
          },
          "sideEffects" => "None"
        }
      ]
    }
  end

  def config_map(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:config_map)
    |> B.name(@artifact_bucket_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def config_map_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:config_map)
    |> B.name(@artifact_pvc_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  def config_map_2(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:config_map)
    |> B.name(@defaults_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(%{})
  end

  def config_map_3(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "disable-affinity-assistant" => "false",
      "disable-creds-init" => "false",
      "enable-api-fields" => "stable",
      "enable-custom-tasks" => "false",
      "enable-tekton-oci-bundles" => "false",
      "require-git-ssh-secret-known-hosts" => "false",
      "running-in-environment-with-injected-sidecars" => "true",
      "send-cloudevents-for-runs" => "false"
    }

    B.build_resource(:config_map)
    |> B.name(@feature_flags_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  def config_map_4(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "version" => "v0.36.0"
    }

    B.build_resource(:config_map)
    |> B.name(@info_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  def config_map_5(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "lease-duration" => "60s",
      "renew-deadline" => "40s",
      "retry-period" => "10s"
    }

    B.build_resource(:config_map)
    |> B.name(@leader_election_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  def config_map_6(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "loglevel.controller" => "debug",
      "loglevel.webhook" => "info",
      "zap-logger-config" => """
          {
      "level": "info",
      "development": false,
      "sampling": {
        "initial": 100,
        "thereafter": 100
      },
      "outputPaths": ["stdout"],
      "errorOutputPaths": ["stderr"],
      "encoding": "json",
      "encoderConfig": {
        "timeKey": "ts",
        "levelKey": "level",
        "nameKey": "logger",
        "callerKey": "caller",
        "messageKey": "msg",
        "stacktraceKey": "stacktrace",
        "lineEnding": "",
        "levelEncoder": "",
        "timeEncoder": "iso8601",
        "durationEncoder": "",
        "callerEncoder": ""
      }
      }
      """
    }

    B.build_resource(:config_map)
    |> B.name(@logging_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(data)
  end

  def config_map_7(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:config_map)
    |> B.name(@observability_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.data(%{})
  end

  def config_map_8(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:config_map)
    |> B.name(@registry_cert_config_name)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
  end

  defp env do
    [
      %{
        "name" => "SYSTEM_NAMESPACE",
        "valueFrom" => %{
          "fieldRef" => %{
            "fieldPath" => "metadata.namespace"
          }
        }
      },
      %{
        "name" => "CONFIG_LOGGING_NAME",
        "value" => @logging_config_name
      },
      %{
        "name" => "CONFIG_OBSERVABILITY_NAME",
        "value" => @observability_config_name
      },
      %{
        "name" => "CONFIG_LEADERELECTION_NAME",
        "value" => @leader_election_config_name
      },
      %{
        "name" => "CONFIG_FEATURE_FLAGS_NAME",
        "value" => @feature_flags_config_name
      },
      %{
        "name" => "WEBHOOK_SERVICE_NAME",
        "value" => "tekton-pipelines-webhook"
      },
      %{
        "name" => "WEBHOOK_SECRET_NAME",
        "value" => @webhook_certs_secret_name
      },
      %{
        "name" => "CONFIG_DEFAULTS_NAME",
        "value" => @defaults_config_name
      },
      %{
        "name" => "CONFIG_ARTIFACT_BUCKET_NAME",
        "value" => @artifact_bucket_config_name
      },
      %{
        "name" => "CONFIG_ARTIFACT_PVC_NAME",
        "value" => @artifact_pvc_config_name
      },
      %{
        "name" => "METRICS_DOMAIN",
        "value" => "tekton.dev/pipeline"
      }
    ]
  end

  def deployment(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "controller",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-pipelines",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0",
          "version" => "v0.36.0"
        },
        "name" => "tekton-pipelines-controller",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/component" => "controller",
            "battery/app" => "tekton-pipelines"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/component" => "controller",
              "app.kubernetes.io/instance" => "default",
              "battery/app" => "tekton-pipelines",
              "battery/managed" => "true",
              "pipeline.tekton.dev/release" => "v0.36.0",
              "version" => "v0.36.0"
            }
          },
          "spec" => %{
            "affinity" => %{
              "nodeAffinity" => %{
                "requiredDuringSchedulingIgnoredDuringExecution" => %{
                  "nodeSelectorTerms" => [
                    %{
                      "matchExpressions" => [
                        %{
                          "key" => "kubernetes.io/os",
                          "operator" => "NotIn",
                          "values" => [
                            "windows"
                          ]
                        }
                      ]
                    }
                  ]
                }
              }
            },
            "containers" => [
              %{
                "args" => [
                  "-kubeconfig-writer-image",
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/kubeconfigwriter:v0.36.0@sha256:b28878bf7f6e3770cdc2d2d72e022fa474c61d471fa2792ecf485486c9d2ca1f",
                  "-git-image",
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/git-init:v0.36.0@sha256:46c3f46f68410666b3ca3f13c4fd398a05413239f257fe9842fc3f7c622f74db",
                  "-entrypoint-image",
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/entrypoint:v0.36.0@sha256:71df923547c2b89515db4089f2d5c3da495dc7b89bc43408853f89a4d7475fc8",
                  "-nop-image",
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/nop:v0.36.0@sha256:44b51ab8b360af58716ebfa34adbd8916050e0fc49ff6a1ddf44c07a6e9b63e9",
                  "-imagedigest-exporter-image",
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/imagedigestexporter:v0.36.0@sha256:b92c59376be46126ec6954ccba40bc882b96e6f2078a7bcdb927f50d8dca4a14",
                  "-pr-image",
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/pullrequest-init:v0.36.0@sha256:69e5d88431b074e611a1ea51a8a4c388b4ecf48f2569695f65898ecdaad59e13",
                  "-workingdirinit-image",
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/workingdirinit:v0.36.0@sha256:1f028b78a04e08a23bf8dd9d1f625b997e59a9b4a8f921c8bcadf781abb9049e",
                  "-gsutil-image",
                  "gcr.io/google.com/cloudsdktool/cloud-sdk@sha256:27b2c22bf259d9bc1a291e99c63791ba0c27a04d2db0a43241ba0f1f20f4067f",
                  "-shell-image",
                  "ghcr.io/distroless/busybox@sha256:19f02276bf8dbdd62f069b922f10c65262cc34b710eea26ff928129a736be791",
                  "-shell-image-win",
                  "mcr.microsoft.com/powershell:nanoserver@sha256:b6d5ff841b78bdf2dfed7550000fd4f3437385b8fa686ec0f010be24777654d6"
                ],
                "env" => env(),
                "image" =>
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/controller:v0.36.0@sha256:303da752778cfb1f9b25e1b4b2db0a6754dc4029f2246eca79cc9f9ec16ae201",
                "livenessProbe" => %{
                  "httpGet" => %{
                    "path" => "/health",
                    "port" => "probes",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "timeoutSeconds" => 5
                },
                "name" => "tekton-pipelines-controller",
                "ports" => [
                  %{
                    "containerPort" => 9090,
                    "name" => "metrics"
                  },
                  %{
                    "containerPort" => 8008,
                    "name" => "profiling"
                  },
                  %{
                    "containerPort" => 8080,
                    "name" => "probes"
                  }
                ],
                "readinessProbe" => %{
                  "httpGet" => %{
                    "path" => "/readiness",
                    "port" => "probes",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "timeoutSeconds" => 5
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{
                    "drop" => [
                      "all"
                    ]
                  },
                  "runAsGroup" => 65_532,
                  "runAsUser" => 65_532
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/etc/config-logging",
                    "name" => "config-logging"
                  },
                  %{
                    "mountPath" => "/etc/config-registry-cert",
                    "name" => "config-registry-cert"
                  }
                ]
              }
            ],
            "serviceAccountName" => @controller_service_account_name,
            "volumes" => [
              %{
                "configMap" => %{
                  "name" => @logging_config_name
                },
                "name" => "config-logging"
              },
              %{
                "configMap" => %{
                  "name" => @registry_cert_config_name
                },
                "name" => "config-registry-cert"
              }
            ]
          }
        }
      }
    }
  end

  def service(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "controller",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-pipelines",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0",
          "version" => "v0.36.0"
        },
        "name" => @controller_service_name,
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "http-metrics",
            "port" => 9090,
            "protocol" => "TCP",
            "targetPort" => 9090
          },
          %{
            "name" => "http-profiling",
            "port" => 8008,
            "targetPort" => 8008
          },
          %{
            "name" => "probes",
            "port" => 8080
          }
        ],
        "selector" => %{
          "app.kubernetes.io/component" => "controller",
          "battery/app" => "tekton-pipelines"
        }
      }
    }
  end

  def horizontal_pod_autoscaler(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "autoscaling/v2beta2",
      "kind" => "HorizontalPodAutoscaler",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "webhook",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-pipelines",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0",
          "version" => "v0.36.0"
        },
        "name" => "tekton-pipelines-webhook",
        "namespace" => namespace
      },
      "spec" => %{
        "maxReplicas" => 5,
        "metrics" => [
          %{
            "resource" => %{
              "name" => "cpu",
              "target" => %{
                "averageUtilization" => 80,
                "type" => "Utilization"
              }
            },
            "type" => "Resource"
          }
        ],
        "minReplicas" => 1,
        "scaleTargetRef" => %{
          "apiVersion" => "apps/v1",
          "kind" => "Deployment",
          "name" => "tekton-pipelines-webhook"
        }
      }
    }
  end

  def deployment_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "app.kubernetes.io/component" => "webhook",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-pipelines",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0",
          "version" => "v0.36.0"
        },
        "name" => "tekton-pipelines-webhook",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{
          "matchLabels" => %{
            "app.kubernetes.io/component" => "webhook",
            "app.kubernetes.io/instance" => "default",
            "battery/app" => "tekton-pipelines"
          }
        },
        "template" => %{
          "metadata" => %{
            "labels" => %{
              "app.kubernetes.io/component" => "webhook",
              "app.kubernetes.io/instance" => "default",
              "battery/app" => "tekton-pipelines",
              "battery/managed" => "true",
              "pipeline.tekton.dev/release" => "v0.36.0",
              "version" => "v0.36.0"
            }
          },
          "spec" => %{
            "affinity" => %{
              "nodeAffinity" => %{
                "requiredDuringSchedulingIgnoredDuringExecution" => %{
                  "nodeSelectorTerms" => [
                    %{
                      "matchExpressions" => [
                        %{
                          "key" => "kubernetes.io/os",
                          "operator" => "NotIn",
                          "values" => [
                            "windows"
                          ]
                        }
                      ]
                    }
                  ]
                }
              },
              "podAntiAffinity" => %{
                "preferredDuringSchedulingIgnoredDuringExecution" => [
                  %{
                    "podAffinityTerm" => %{
                      "labelSelector" => %{
                        "matchLabels" => %{
                          "app.kubernetes.io/component" => "webhook",
                          "app.kubernetes.io/instance" => "default",
                          "battery/app" => "tekton-pipelines"
                        }
                      },
                      "topologyKey" => "kubernetes.io/hostname"
                    },
                    "weight" => 100
                  }
                ]
              }
            },
            "containers" => [
              %{
                "env" => env(),
                "image" =>
                  "gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/webhook:v0.36.0@sha256:d762e0e8033609e6908ce7689018624c9b6443a48bb0ecccf108eb88ccbde331",
                "livenessProbe" => %{
                  "httpGet" => %{
                    "path" => "/health",
                    "port" => "probes",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "timeoutSeconds" => 5
                },
                "name" => "webhook",
                "ports" => [
                  %{
                    "containerPort" => 9090,
                    "name" => "metrics"
                  },
                  %{
                    "containerPort" => 8008,
                    "name" => "profiling"
                  },
                  %{
                    "containerPort" => 8443,
                    "name" => "https-webhook"
                  },
                  %{
                    "containerPort" => 8080,
                    "name" => "probes"
                  }
                ],
                "readinessProbe" => %{
                  "httpGet" => %{
                    "path" => "/readiness",
                    "port" => "probes",
                    "scheme" => "HTTP"
                  },
                  "initialDelaySeconds" => 5,
                  "periodSeconds" => 10,
                  "timeoutSeconds" => 5
                },
                "resources" => %{
                  "limits" => %{
                    "cpu" => "500m",
                    "memory" => "500Mi"
                  },
                  "requests" => %{
                    "cpu" => "100m",
                    "memory" => "100Mi"
                  }
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{
                    "drop" => [
                      "all"
                    ]
                  },
                  "runAsGroup" => 65_532,
                  "runAsUser" => 65_532
                }
              }
            ],
            "serviceAccountName" => @webhook_service_account_name
          }
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
        "labels" => %{
          "app.kubernetes.io/component" => "webhook",
          "app.kubernetes.io/instance" => "default",
          "battery/app" => "tekton-webhook",
          "battery/managed" => "true",
          "pipeline.tekton.dev/release" => "v0.36.0",
          "version" => "v0.36.0"
        },
        "name" => @webhook_service_name,
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "http-metrics",
            "port" => 9090,
            "targetPort" => 9090
          },
          %{
            "name" => "http-profiling",
            "port" => 8008,
            "targetPort" => 8008
          },
          %{
            "name" => "https-webhook",
            "port" => 443,
            "targetPort" => 8443
          },
          %{
            "name" => "probes",
            "port" => 8080
          }
        ],
        "selector" => %{
          "app.kubernetes.io/component" => "webhook",
          "battery/app" => "tekton-pipelines"
        }
      }
    }
  end

  def task(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "tekton.dev/v1beta1",
      "kind" => "Task",
      "metadata" => %{
        "annotations" => %{
          "tekton.dev/categories" => "Image Build",
          "tekton.dev/displayName" => "Build and upload container image using Kaniko",
          "tekton.dev/pipelines.minVersion" => "0.17.0",
          "tekton.dev/platforms" => "linux/amd64",
          "tekton.dev/tags" => "image-build"
        },
        "labels" => %{
          "battery/app" => "tekton-pipeline",
          "battery/managed" => "true"
        },
        "namespace" => namespace,
        "name" => "kaniko"
      },
      "spec" => %{
        "description" =>
          "This Task builds a simple Dockerfile with kaniko and pushes to a registry. This Task stores the image name and digest as results, allowing Tekton Chains to pick up that an image was built & sign it.",
        "params" => [
          %{
            "description" => "Name (reference) of the image to build.",
            "name" => "IMAGE"
          },
          %{
            "default" => "./Dockerfile",
            "description" => "Path to the Dockerfile to build.",
            "name" => "DOCKERFILE"
          },
          %{
            "default" => "./",
            "description" => "The build context used by Kaniko.",
            "name" => "CONTEXT"
          },
          %{
            "default" => [],
            "name" => "EXTRA_ARGS",
            "type" => "array"
          },
          %{
            "default" =>
              "gcr.io/kaniko-project/executor:v1.5.1@sha256:c6166717f7fe0b7da44908c986137ecfeab21f31ec3992f6e128fff8a94be8a5",
            "description" => "The image on which builds will run (default is v1.5.1)",
            "name" => "BUILDER_IMAGE"
          }
        ],
        "results" => [
          %{
            "description" => "Digest of the image just built.",
            "name" => "IMAGE_DIGEST"
          },
          %{
            "description" => "URL of the image just built.",
            "name" => "IMAGE_URL"
          }
        ],
        "steps" => [
          %{
            "args" => [
              "$(params.EXTRA_ARGS)",
              "--dockerfile=$(params.DOCKERFILE)",
              "--context=$(workspaces.source.path)/$(params.CONTEXT)",
              "--destination=$(params.IMAGE)",
              "--digest-file=$(results.IMAGE_DIGEST.path)"
            ],
            "image" => "$(params.BUILDER_IMAGE)",
            "name" => "build-and-push",
            "securityContext" => %{
              "runAsUser" => 0
            },
            "workingDir" => "$(workspaces.source.path)"
          },
          %{
            "image" =>
              "docker.io/library/bash:5.1.4@sha256:b208215a4655538be652b2769d82e576bc4d0a2bb132144c060efc5be8c3f5d6",
            "name" => "write-url",
            "script" =>
              "set -e\nimage=\"$(params.IMAGE)\"\necho -n \"$%{image}\" | tee \"$(results.IMAGE_URL.path)\"\n"
          }
        ],
        "workspaces" => [
          %{
            "description" => "Holds the context and Dockerfile",
            "name" => "source"
          },
          %{
            "description" => "Includes a docker `config.json`",
            "mountPath" => "/kaniko/.docker",
            "name" => "dockerconfig",
            "optional" => true
          }
        ]
      }
    }
  end

  def crd(config) do
    :crd
    |> get_resource()
    |> yaml()
    |> Enum.map(fn crd ->
      change_conversion(crd, config)
    end)
  end

  def change_conversion(%{"spec" => %{"conversion" => conversion}} = crd, config),
    do: do_chang_conversion(crd, conversion, new_service(config))

  def change_conversion(%{spec: %{conversion: conversion}} = crd, config),
    do: do_chang_conversion(crd, conversion, new_service(config))

  def change_conversion(crd, _), do: crd

  defp do_chang_conversion(crd, conversion, new_service) do
    new_conversion = put_in(conversion, ~w(webhook clientConfig service), new_service)

    put_in(crd, ~w(spec conversion), new_conversion)
  end

  defp new_service(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "name" => @webhook_service_name,
      "namespace" => namespace
    }
  end

  def materialize(config) do
    %{
      "/crd" => crd(config),
      "/pod_security_policy" => pod_security_policy(config),
      "/cluster_role" => cluster_role(config),
      "/cluster_role_1" => cluster_role_1(config),
      "/cluster_role_2" => cluster_role_2(config),
      "/cluster_role_3" => cluster_role_3(config),
      "/cluster_role_4" => cluster_role_4(config),
      "/role" => role(config),
      "/role_1" => role_1(config),
      "/role_2" => role_2(config),
      "/role_3" => role_3(config),
      "/9/service_account" => service_account(config),
      "/10/service_account_1" => service_account_1(config),
      "/11/cluster_role_binding" => cluster_role_binding(config),
      "/12/cluster_role_binding_1" => cluster_role_binding_1(config),
      "/13/cluster_role_binding_2" => cluster_role_binding_2(config),
      "/14/role_binding" => role_binding(config),
      "/15/role_binding_1" => role_binding_1(config),
      "/16/role_binding_2" => role_binding_2(config),
      "/17/role_binding_3" => role_binding_3(config),
      "/18/role_binding_4" => role_binding_4(config),
      "/19/secret" => secret(config),
      "/20/validating_webhook_configuration" => validating_webhook_configuration(config),
      "/21/mutating_webhook_configuration" => mutating_webhook_configuration(config),
      "/22/validating_webhook_configuration_1" => validating_webhook_configuration_1(config),
      "/25/config_map" => config_map(config),
      "/26/config_map_1" => config_map_1(config),
      "/27/config_map_2" => config_map_2(config),
      "/28/config_map_3" => config_map_3(config),
      "/29/config_map_4" => config_map_4(config),
      "/30/config_map_5" => config_map_5(config),
      "/31/config_map_6" => config_map_6(config),
      "/32/config_map_7" => config_map_7(config),
      "/33/config_map_8" => config_map_8(config),
      "/34/deployment" => deployment(config),
      "/35/service" => service(config),
      "/36/horizontal_pod_autoscaler" => horizontal_pod_autoscaler(config),
      "/37/deployment_1" => deployment_1(config),
      "/38/service_1" => service_1(config),
      "/39/task" => task(config)
    }
  end
end
