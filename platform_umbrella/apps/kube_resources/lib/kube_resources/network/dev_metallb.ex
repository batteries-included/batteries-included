defmodule KubeResources.DevMetalLB do
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeResources.NetworkSettings, as: Settings
  alias KubeExt.Builder, as: B

  @app_name "dev-metallb"

  resource(:ip_pool, battery, state) do
    namespace = loadbalancer_namespace(state)
    addresses = Settings.metallb_ip_pools(battery.config)
    spec = %{addresses: addresses}

    B.build_resource(:ip_address_pool)
    |> B.name("dev-ip-pool")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:l2, _battery, state) do
    namespace = loadbalancer_namespace(state)
    spec = %{}

    B.build_resource(:l2_advertisement)
    |> B.name("empty")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end
end
