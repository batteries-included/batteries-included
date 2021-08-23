defmodule KubeResources.Network do
  alias KubeResources.Kong
  alias KubeResources.Nginx

  def materialize(%{} = config) do
    %{}
    |> Map.merge(nginx(config))
    |> Map.merge(kong(config))
  end

  def kong(%{"kong.install" => false}), do: %{}

  def kong(config) do
    %{
      "/kong/0/crds" => Kong.crd(config),
      "/kong/1/service_account" => Kong.service_account(config),
      "/kong/1/cluster_role" => Kong.cluster_role(config),
      "/kong/1/cluster_role_binding" => Kong.cluster_role_binding(config),
      "/kong/1/role" => Kong.role(config),
      "/kong/1/role_binding" => Kong.role_binding(config),
      "/kong/1/service" => Kong.service(config),
      "/kong/1/deployment" => Kong.deployment(config),
      "/kong/1/pod" => Kong.pod(config),
      "/kong/1/pod_1" => Kong.pod_1(config)
    }
  end

  # It looks like knog will be the defacto ingress. So unless there's some reason don't install nginx by default.
  def nginx(%{"nginx.install" => true} = config) do
    %{
      "/nginx/0/service_account" => Nginx.service_account(config),
      "/nginx/0/config_map" => Nginx.config_map(config),
      "/nginx/0/cluster_role" => Nginx.cluster_role(config),
      "/nginx/0/cluster_role_binding" => Nginx.cluster_role_binding(config),
      "/nginx/0/role" => Nginx.role(config),
      "/nginx/0/role_binding" => Nginx.role_binding(config),
      "/nginx/0/service" => Nginx.service(config),
      "/nginx/0/deployment" => Nginx.deployment(config)
    }
  end

  def nginx(_), do: %{}
end
