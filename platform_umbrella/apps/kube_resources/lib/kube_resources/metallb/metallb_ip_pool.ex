defmodule KubeResources.MetalLBIPPool do
  use KubeExt.ResourceGenerator

  import CommonCore.SystemState.Namespaces

  alias KubeExt.Builder, as: B

  @app_name "metallb-ip-pool"

  multi_resource(:ip_pool, _battery, state) do
    namespace = base_namespace(state)

    Enum.map(state.ip_address_pools, fn pool ->
      spec = %{
        addresses: [pool.subnet],
        # .0 and .255 are reserved for broadcast and network
        # when they are at the begining and ending of an ip
        # range historically.
        #
        # If there's no need for a broadcast
        # (for example on an explictly bridged network)
        # Or if there's no need for a network ip
        # (bridged network, or a split cidr range)
        # we could get away with using those ip's
        #
        # However there's enough crappy network equipmtment
        # that think these ips are bogons so, avoiding is better.
        avoidBuggyIPs: true
      }

      B.build_resource(:metal_ip_address_pool)
      |> B.name(pool.name)
      |> B.namespace(namespace)
      |> B.app_labels(@app_name)
      |> B.spec(spec)
    end)
  end

  resource(:l2, _battery, state) do
    namespace = base_namespace(state)
    spec = %{"ipAddressPools" => Enum.map(state.ip_address_pools, & &1.name)}

    B.build_resource(:metal_l2_advertisement)
    |> B.name("core")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end
end
