defmodule KubeResources.DevMetalLB do
  use KubeExt.ResourceGenerator

  alias KubeResources.NetworkSettings, as: Settings

  @app "dev_metallb"

  resource(:ip_pool, battery, _state) do
    namespace = Settings.metallb_namespace(battery.config)
    addresses = Settings.metallb_ip_pools(battery.config)
    spec = %{addresses: addresses}

    B.build_resource(:ip_address_pool)
    |> B.name("dev-ip-pool")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  resource(:l2, battery, _state) do
    namespace = Settings.metallb_namespace(battery.config)
    spec = %{}

    B.build_resource(:l2_advertisement)
    |> B.name("empty")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end
end
