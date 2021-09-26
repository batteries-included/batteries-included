defmodule KubeResources.Network do
  alias KubeResources.Ingress
  alias KubeResources.Istio
  alias KubeResources.Kong
  alias KubeResources.Nginx
  alias KubeResources.VirtualService

  def materialize(%{} = config) do
    %{}
    |> Map.merge(nginx(config))
    |> Map.merge(kong(config))
    |> Map.merge(istio(config))
  end

  def kong(%{"kong.run" => true} = config) do
    %{
      "/kong/0/crds" => Kong.crd(config),
      "/kong/1/service_account" => Kong.service_account(config),
      "/kong/1/cluster_role" => Kong.cluster_role(config),
      "/kong/1/cluster_role_binding" => Kong.cluster_role_binding(config),
      "/kong/1/role" => Kong.role(config),
      "/kong/1/role_binding" => Kong.role_binding(config),
      "/kong/1/service" => Kong.service(config),
      "/kong/1/service_1" => Kong.service_1(config),
      "/kong/1/deployment" => Kong.deployment(config),
      "/kong/1/pod" => Kong.pod(config),
      "/kong/1/pod_1" => Kong.pod_1(config),
      "/kong/1/pom_plugin" => Kong.prometheus_plugin(config)
    }
  end

  def kong(_), do: %{}

  def nginx(%{"nginx.run" => true} = config) do
    %{}
    |> Map.put("/nginx/0/service_account", Nginx.service_account(config))
    |> Map.put("/nginx/0/config_map", Nginx.config_map(config))
    |> Map.put("/nginx/0/cluster_role", Nginx.cluster_role(config))
    |> Map.put("/nginx/0/cluster_role_binding", Nginx.cluster_role_binding(config))
    |> Map.put("/nginx/0/role", Nginx.role(config))
    |> Map.put("/nginx/0/role_binding", Nginx.role_binding(config))
    |> Map.put("/nginx/0/service", Nginx.service(config))
    |> Map.put("/nginx/0/deployment", Nginx.deployment(config))
    |> Map.merge(Ingress.materialize(config))
  end

  def nginx(_config), do: %{}

  def istio(%{"istio.run" => true} = config) do
    %{}
    |> Map.put("/istio/0/crd", Istio.crd(config))
    |> Map.put("/istio/0/cluster_role", Istio.cluster_role(config))
    |> Map.put("/istio/0/cluster_role_binding", Istio.cluster_role_binding(config))
    |> Map.put("/istio/0/service_account", Istio.service_account(config))
    |> Map.put("/istio/1/deployment", Istio.deployment(config))
    |> Map.put("/istio/2/service", Istio.service(config))
    |> Map.put("/istio/2/istio", Istio.istio(config))
    |> Map.put("/istio/3/gateway", Istio.gateway(config))
    |> Map.merge(VirtualService.materialize(config))
  end

  def istio(_config), do: %{}
end
