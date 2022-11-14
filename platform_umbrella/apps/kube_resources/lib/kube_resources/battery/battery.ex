defmodule KubeResources.Battery do
  alias KubeExt.Builder, as: B

  @app_name "batteries-included"

  def namespace(battery, _state) do
    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name(battery.config.namespace)
    |> B.label("istio-injection", "enabled")
  end

  def service_account(battery, _state) do
    B.build_resource(:service_account)
    |> B.namespace(battery.config.namespace)
    |> B.name("battery-admin")
    |> B.app_labels(@app_name)
  end

  def cluster_role_binding(battery, _state) do
    B.build_resource(:cluster_role_binding)
    |> B.name("battery-admin-cluster-admin")
    |> B.app_labels(@app_name)
    |> Map.put(
      "roleRef",
      B.build_cluster_role_ref("cluster-admin")
    )
    |> Map.put("subjects", [
      B.build_service_account("battery-admin", battery.config.namespace)
    ])
  end

  def materialize(battery, state) do
    %{
      "/namespace" => namespace(battery, state),
      "/service_account" => service_account(battery, state),
      "/cluster_role_binding" => cluster_role_binding(battery, state)
    }
  end
end
