defmodule KubeResources.GitlabRunner do
  @moduledoc false

  alias KubeResources.DevtoolsSettings

  def service_account_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ServiceAccount",
      "metadata" => %{
        "name" => "battery-gitlab-runner",
        "labels" => %{"battery/app" => "battery-gitlab-runner", "battery/managed" => "True"},
        "namespace" => namespace
      }
    }
  end

  def config_map_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "ConfigMap",
      "metadata" => %{
        "name" => "battery-gitlab-runner",
        "labels" => %{"battery/app" => "battery-gitlab-runner", "battery/managed" => "True"},
        "namespace" => namespace
      },
      "data" => %{
        "entrypoint" =>
          "#!/bin/bash\nset -e\nmkdir -p /home/gitlab-runner/.gitlab-runner/\ncp /configmaps/config.toml /home/gitlab-runner/.gitlab-runner/\n\n# Set up environment variables for cache\nif [[ -f /secrets/accesskey && -f /secrets/secretkey ]]; then\n  export CACHE_S3_ACCESS_KEY=$(cat /secrets/accesskey)\n  export CACHE_S3_SECRET_KEY=$(cat /secrets/secretkey)\nfi\n\nif [[ -f /secrets/gcs-applicaton-credentials-file ]]; then\n  export GOOGLE_APPLICATION_CREDENTIALS=\"/secrets/gcs-applicaton-credentials-file\"\nelif [[ -f /secrets/gcs-application-credentials-file ]]; then\n  export GOOGLE_APPLICATION_CREDENTIALS=\"/secrets/gcs-application-credentials-file\"\nelse\n  if [[ -f /secrets/gcs-access-id && -f /secrets/gcs-private-key ]]; then\n    export CACHE_GCS_ACCESS_ID=$(cat /secrets/gcs-access-id)\n    # echo -e used to make private key multiline (in google json auth key private key is oneline with \\n)\n    export CACHE_GCS_PRIVATE_KEY=$(echo -e $(cat /secrets/gcs-private-key))\n  fi\nfi\n\nif [[ -f /secrets/azure-account-name && -f /secrets/azure-account-key ]]; then\n  export CACHE_AZURE_ACCOUNT_NAME=$(cat /secrets/azure-account-name)\n  export CACHE_AZURE_ACCOUNT_KEY=$(cat /secrets/azure-account-key)\nfi\n\nif [[ -f /secrets/runner-registration-token ]]; then\n  export REGISTRATION_TOKEN=$(cat /secrets/runner-registration-token)\nfi\n\nif [[ -f /secrets/runner-token ]]; then\n  export CI_SERVER_TOKEN=$(cat /secrets/runner-token)\nfi\n\n# Register the runner\nif ! sh /configmaps/register-the-runner; then\n  exit 1\nfi\n\n# Run pre-entrypoint-script\nif ! bash /configmaps/pre-entrypoint-script; then\n  exit 1\nfi\n\n# Start the runner\nexec /entrypoint run --user=gitlab-runner \\\n  --working-directory=/home/gitlab-runner\n",
        "config.toml" =>
          "concurrent = 9\ncheck_interval = 30\nlog_level = \"info\"\nlisten_address = ':9252'\n",
        "config.template.toml" =>
          "[[runners]]\n  executor = \"kubernetes\"\n  [runners.kubernetes]\n    image = \"ubuntu:20.04\"\n",
        "configure" => "set -e\ncp /init-secrets/* /secrets\n",
        "register-the-runner" =>
          "#!/bin/bash\nMAX_REGISTER_ATTEMPTS=30\n\nfor i in $(seq 1 \"$%{MAX_REGISTER_ATTEMPTS}\"); do\n  echo \"Registration attempt $%{i} of $%{MAX_REGISTER_ATTEMPTS}\"\n  /entrypoint register \\\n    --template-config /configmaps/config.template.toml \\\n    --non-interactive\n\n  retval=$?\n\n  if [ $%{retval} = 0 ]; then\n    break\n  elif [ $%{i} = $%{MAX_REGISTER_ATTEMPTS} ]; then\n    exit 1\n  fi\n\n  sleep 5\ndone\n\nexit 0\n",
        "check-live" =>
          "#!/bin/bash\nif /usr/bin/pgrep -f .*register-the-runner; then\n  exit 0\nelif /usr/bin/pgrep gitlab.*runner; then\n  exit 0\nelse\n  exit 1\nfi\n",
        "pre-entrypoint-script" => ""
      }
    }
  end

  def role_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "Role",
      "metadata" => %{
        "name" => "battery-gitlab-runner",
        "labels" => %{"battery/app" => "battery-gitlab-runner", "battery/managed" => "True"},
        "namespace" => namespace
      },
      "rules" => [%{"apiGroups" => [""], "resources" => ["*"], "verbs" => ["*"]}]
    }
  end

  def role_binding_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "rbac.authorization.k8s.io/v1",
      "kind" => "RoleBinding",
      "metadata" => %{
        "name" => "battery-gitlab-runner",
        "labels" => %{"battery/app" => "battery-gitlab-runner", "battery/managed" => "True"},
        "namespace" => namespace
      },
      "roleRef" => %{
        "apiGroup" => "rbac.authorization.k8s.io",
        "kind" => "Role",
        "name" => "battery-gitlab-runner"
      },
      "subjects" => [
        %{
          "kind" => "ServiceAccount",
          "name" => "battery-gitlab-runner",
          "namespace" => namespace
        }
      ]
    }
  end

  def deployment_0(config) do
    namespace = DevtoolsSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "name" => "battery-gitlab-runner",
        "labels" => %{"battery/app" => "battery-gitlab-runner", "battery/managed" => "True"},
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{"matchLabels" => %{"battery/app" => "battery-gitlab-runner"}},
        "template" => %{
          "metadata" => %{
            "labels" => %{"battery/app" => "battery-gitlab-runner", "battery/managed" => "True"},
            "annotations" => %{"prometheus.io/scrape" => "true", "prometheus.io/port" => "9252"}
          },
          "spec" => %{
            "securityContext" => %{"runAsUser" => 100, "fsGroup" => 65_533},
            "terminationGracePeriodSeconds" => 3600,
            "initContainers" => [
              %{
                "name" => "configure",
                "command" => ["sh", "/configmaps/configure"],
                "image" => "gitlab/gitlab-runner:alpine-v13.12.0",
                "imagePullPolicy" => "IfNotPresent",
                "securityContext" => %{"allowPrivilegeEscalation" => false},
                "env" => environment(config),
                "volumeMounts" => [
                  %{"name" => "runner-secrets", "mountPath" => "/secrets", "readOnly" => false},
                  %{"name" => "configmaps", "mountPath" => "/configmaps", "readOnly" => true},
                  %{
                    "name" => "init-runner-secrets",
                    "mountPath" => "/init-secrets",
                    "readOnly" => true
                  }
                ],
                "resources" => %{}
              }
            ],
            "serviceAccountName" => "battery-gitlab-runner",
            "containers" => [
              %{
                "name" => "battery-gitlab-runner",
                "image" => "gitlab/gitlab-runner:alpine-v13.12.0",
                "imagePullPolicy" => "IfNotPresent",
                "securityContext" => %{"allowPrivilegeEscalation" => false},
                "command" => ["/bin/bash", "/configmaps/entrypoint"],
                "env" => environment(config),
                "livenessProbe" => %{
                  "exec" => %{"command" => ["/bin/bash", "/configmaps/check-live"]},
                  "initialDelaySeconds" => 60,
                  "timeoutSeconds" => 1,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "failureThreshold" => 3
                },
                "readinessProbe" => %{
                  "exec" => %{"command" => ["/usr/bin/pgrep", "gitlab.*runner"]},
                  "initialDelaySeconds" => 10,
                  "timeoutSeconds" => 1,
                  "periodSeconds" => 10,
                  "successThreshold" => 1,
                  "failureThreshold" => 3
                },
                "ports" => [%{"name" => "metrics", "containerPort" => 9252}],
                "volumeMounts" => [
                  %{"name" => "runner-secrets", "mountPath" => "/secrets"},
                  %{
                    "name" => "etc-gitlab-runner",
                    "mountPath" => "/home/gitlab-runner/.gitlab-runner"
                  },
                  %{"name" => "configmaps", "mountPath" => "/configmaps"}
                ],
                "resources" => %{}
              }
            ],
            "volumes" => [
              %{"name" => "runner-secrets", "emptyDir" => %{"medium" => "Memory"}},
              %{"name" => "etc-gitlab-runner", "emptyDir" => %{"medium" => "Memory"}},
              %{
                "name" => "init-runner-secrets",
                "projected" => %{
                  "sources" => [
                    %{
                      "secret" => %{
                        "name" => "gitlab-runner-secret",
                        "items" => [
                          %{
                            "key" => "runner-registration-token",
                            "path" => "runner-registration-token"
                          },
                          %{"key" => "runner-token", "path" => "runner-token"}
                        ]
                      }
                    }
                  ]
                }
              },
              %{"name" => "configmaps", "configMap" => %{"name" => "battery-gitlab-runner"}}
            ]
          }
        }
      }
    }
  end

  def materialize(config) do
    %{
      "/0/service_account_0" => service_account_0(config),
      "/1/config_map_0" => config_map_0(config),
      "/2/role_0" => role_0(config),
      "/3/role_binding_0" => role_binding_0(config),
      "/5/deployment_0" => deployment_0(config)
    }
  end

  defp environment(config) do
    namespace = DevtoolsSettings.namespace(config)

    [
      %{"name" => "KUBERNETES_IMAGE"},
      envvar("CI_SERVER_URL", "https://gitlab.com/"),
      envvar("CLONE_URL", ""),
      envvar("RUNNER_REQUEST_CONCURRENCY", "1"),
      envvar("RUNNER_EXECUTOR", "kubernetes"),
      envvar("REGISTER_LOCKED", "true"),
      envvar("RUNNER_TAG_LIST", ""),
      envvar("KUBERNETES_NAMESPACE", namespace),
      envvar("KUBERNETES_CPU_LIMIT", ""),
      envvar("KUBERNETES_CPU_LIMIT_OVERWRITE_MAX_ALLOWED", ""),
      envvar("KUBERNETES_MEMORY_LIMIT", ""),
      envvar("KUBERNETES_MEMORY_LIMIT_OVERWRITE_MAX_ALLOWED", ""),
      envvar("KUBERNETES_CPU_REQUEST", ""),
      envvar("KUBERNETES_CPU_REQUEST_OVERWRITE_MAX_ALLOWED", ""),
      envvar("KUBERNETES_MEMORY_REQUEST", ""),
      envvar("KUBERNETES_MEMORY_REQUEST_OVERWRITE_MAX_ALLOWED", ""),
      envvar("KUBERNETES_SERVICE_ACCOUNT", "battery-gitlab-runner"),
      envvar("KUBERNETES_SERVICE_CPU_LIMIT", ""),
      envvar("KUBERNETES_SERVICE_MEMORY_LIMIT", ""),
      envvar("KUBERNETES_SERVICE_CPU_REQUEST", ""),
      envvar("KUBERNETES_SERVICE_MEMORY_REQUEST", ""),
      envvar("KUBERNETES_HELPER_CPU_LIMIT", ""),
      envvar("KUBERNETES_HELPER_MEMORY_LIMIT", ""),
      envvar("KUBERNETES_HELPER_CPU_REQUEST", ""),
      envvar("KUBERNETES_HELPER_MEMORY_REQUEST", ""),
      envvar("KUBERNETES_HELPER_IMAGE", ""),
      envvar("KUBERNETES_PULL_POLICY", "")
    ]
  end

  defp envvar(name, value) do
    %{"name" => name, "value" => value}
  end
end
