defmodule KubeResources.EchoServer do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeRawResources.BatterySettings
  alias KubeResources.IstioConfig.VirtualService

  @app_name "echo"

  def materialize(config) do
    %{
      "/service" => service(config),
      "/deployment" => deployment(config)
    }
  end

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
        %{"name" => "http", "protocol" => "TCP", "targetPort" => 8080, "port" => 8080}
      ])

    B.build_resource(:service)
    |> B.name("echo")
    |> B.app_labels(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  def deployment(config) do
    namespace = BatterySettings.namespace(config)

    template =
      %{}
      |> B.app_labels(@app_name)
      |> B.spec(%{"containers" => [echo_container()]})

    spec =
      %{}
      |> B.match_labels_selector(@app_name)
      |> B.template(template)
      |> Map.put("replicas", 1)

    B.build_resource(:deployment)
    |> B.name("echo")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  defp echo_container do
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
  end

  def virtual_service(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.name("echo")
    |> B.spec(VirtualService.rewriting("/x/echo", "echo"))
  end
end
