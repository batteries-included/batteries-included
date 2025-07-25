defmodule CommonCore.Resources.GatewayAPI do
  @moduledoc false
  use CommonCore.IncludeResource,
    gatewayclasses_gateway_networking_k8s_io: "priv/manifests/gateway_api/gatewayclasses_gateway_networking_k8s_io.yaml",
    gateways_gateway_networking_k8s_io: "priv/manifests/gateway_api/gateways_gateway_networking_k8s_io.yaml",
    grpcroutes_gateway_networking_k8s_io: "priv/manifests/gateway_api/grpcroutes_gateway_networking_k8s_io.yaml",
    httproutes_gateway_networking_k8s_io: "priv/manifests/gateway_api/httproutes_gateway_networking_k8s_io.yaml",
    referencegrants_gateway_networking_k8s_io: "priv/manifests/gateway_api/referencegrants_gateway_networking_k8s_io.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "gateway_api"

  multi_resource(:crds_istio) do
    Enum.flat_map(@included_resources, &(&1 |> get_resource() |> YamlElixir.read_all_from_string!()))
  end
end
