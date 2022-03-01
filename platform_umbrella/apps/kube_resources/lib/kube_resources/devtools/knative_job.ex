defmodule KubeResources.KnativeDomain do
  @moduledoc false

  alias KubeExt.Builder, as: B

  alias KubeResources.DevtoolsSettings
  @app_name "knative"

  def job(config) do
    namespace = DevtoolsSettings.knative_destination_namespace(config)

    B.build_resource(:job)
    |> B.namespace(namespace)
    |> B.name("default-domain")
    |> B.app_labels(@app_name)
    |> B.spec(spec(config))
  end

  def spec(_config) do
    %{
      "template" => %{
        "metadata" => %{
          "annotations" => %{"sidecar.istio.io/inject" => "false"},
          "labels" => %{
            "battery/app" => @app_name,
            "battery/managed" => "True"
          }
        },
        "spec" => %{
          "serviceAccountName" => "controller",
          "containers" => [
            %{
              "name" => "default-domain",
              "image" =>
                "gcr.io/knative-releases/knative.dev/serving/cmd/default-domain@sha256:87d85b40d59bd90b6656f411edf954f02f4af75f7848261b633e8c4a3ccd715e",
              "args" => ["-magic-dns=sslip.io"],
              "ports" => [%{"name" => "http", "containerPort" => 8080}],
              "readinessProbe" => %{"httpGet" => %{"port" => 8080}},
              "livenessProbe" => %{"httpGet" => %{"port" => 8080}, "failureThreshold" => 6},
              "resources" => %{
                "requests" => %{"cpu" => "100m", "memory" => "100Mi"},
                "limits" => %{"cpu" => "1000m", "memory" => "1000Mi"}
              },
              "securityContext" => %{
                "allowPrivilegeEscalation" => false,
                "readOnlyRootFilesystem" => true,
                "runAsNonRoot" => true
              },
              "env" => [
                %{
                  "name" => "POD_NAME",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                },
                %{
                  "name" => "SYSTEM_NAMESPACE",
                  "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                }
              ]
            }
          ],
          "restartPolicy" => "Never"
        }
      },
      "backoffLimit" => 10
    }
  end

  def materialize(config) do
    %{
      "/0/job" => job(config)
    }
  end
end
