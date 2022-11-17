defmodule KubeResources.MetalLBIPPool do
  use KubeExt.ResourceGenerator

  import KubeExt.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "metallb-ip-pool"

  resource(:ip_pool, battery, state) do
    namespace = loadbalancer_namespace(state)
    addresses = battery.config.pools
    spec = %{addresses: addresses}

    B.build_resource(:ip_address_pool)
    |> B.name("core-ip-pool")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end

  resource(:l2, _battery, state) do
    namespace = loadbalancer_namespace(state)
    spec = %{}

    B.build_resource(:l2_advertisement)
    |> B.name("core")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end
end
