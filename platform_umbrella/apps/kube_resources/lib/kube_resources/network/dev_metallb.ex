defmodule KubeResources.DevMetalLB do
  use KubeExt.ResourceGenerator

  alias KubeRawResources.NetworkSettings, as: Settings

  @app "dev_metallb"

  resource(:ip_pool, config) do
    namespace = Settings.metallb_namespace(config)
    addresses = Settings.metallb_ip_pools(config)
    spec = %{addresses: addresses}

    B.build_resource(:ip_address_pool)
    |> B.name("dev-ip-pool")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end

  resource(:l2, config) do
    namespace = Settings.metallb_namespace(config)
    spec = %{}

    B.build_resource(:l2_advertisement)
    |> B.name("empty")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.spec(spec)
  end
end
