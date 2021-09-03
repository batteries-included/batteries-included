defmodule KubeResources.EchoServer do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeResources.BatterySettings

  @app_name "echo"

  def ingress(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:ingress, "/x/echo", "echo", "http")
    |> B.name("echo")
    |> B.namespace(namespace)
    |> B.rewriting_ingress()
    |> B.app_labels(@app_name)
  end

  def service(config) do
    namespace = BatterySettings.namespace(config)

    spec =
      %{}
      |> B.short_selector(@app_name)
      |> B.ports([
        %{"port" => 80, "name" => "http", "protocol" => "TCP", "targetPort" => 8080}
      ])

    B.build_resource(:service)
    |> B.name("echo")
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = BatterySettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{"app" => "echo", "battery/managed" => "True"},
        "name" => "echo",
        "namespace" => namespace
      },
      "spec" => %{
        "replicas" => 1,
        "selector" => %{"matchLabels" => %{"app" => "echo"}},
        "template" => %{
          "metadata" => %{"labels" => %{"app" => "echo", "battery/managed" => "True"}},
          "spec" => %{
            "containers" => [
              %{
                "image" => "gcr.io/kubernetes-e2e-test-images/echoserver:2.2",
                "name" => "echo",
                "ports" => [%{"containerPort" => 8080}],
                "env" => [
                  %{
                    "name" => "NODE_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "spec.nodeName"}}
                  },
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.name"}}
                  },
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "metadata.namespace"}}
                  },
                  %{
                    "name" => "POD_IP",
                    "valueFrom" => %{"fieldRef" => %{"fieldPath" => "status.podIP"}}
                  }
                ]
              }
            ]
          }
        }
      }
    }
  end
end
