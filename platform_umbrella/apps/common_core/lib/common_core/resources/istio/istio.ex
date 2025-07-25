defmodule CommonCore.Resources.Istio do
  @moduledoc false
  use CommonCore.IncludeResource,
    authorizationpolicies_security_istio_io: "priv/manifests/istio/authorizationpolicies_security_istio_io.yaml",
    destinationrules_networking_istio_io: "priv/manifests/istio/destinationrules_networking_istio_io.yaml",
    envoyfilters_networking_istio_io: "priv/manifests/istio/envoyfilters_networking_istio_io.yaml",
    gateways_networking_istio_io: "priv/manifests/istio/gateways_networking_istio_io.yaml",
    peerauthentications_security_istio_io: "priv/manifests/istio/peerauthentications_security_istio_io.yaml",
    proxyconfigs_networking_istio_io: "priv/manifests/istio/proxyconfigs_networking_istio_io.yaml",
    requestauthentications_security_istio_io: "priv/manifests/istio/requestauthentications_security_istio_io.yaml",
    serviceentries_networking_istio_io: "priv/manifests/istio/serviceentries_networking_istio_io.yaml",
    sidecars_networking_istio_io: "priv/manifests/istio/sidecars_networking_istio_io.yaml",
    telemetries_telemetry_istio_io: "priv/manifests/istio/telemetries_telemetry_istio_io.yaml",
    virtualservices_networking_istio_io: "priv/manifests/istio/virtualservices_networking_istio_io.yaml",
    wasmplugins_extensions_istio_io: "priv/manifests/istio/wasmplugins_extensions_istio_io.yaml",
    workloadentries_networking_istio_io: "priv/manifests/istio/workloadentries_networking_istio_io.yaml",
    workloadgroups_networking_istio_io: "priv/manifests/istio/workloadgroups_networking_istio_io.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "istio"

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.Istio.IstioConfigMapGenerator

  multi_resource(:crds_istio) do
    Enum.flat_map(@included_resources, &(&1 |> get_resource() |> YamlElixir.read_all_from_string!()))
  end

  resource(:config_map_main, battery, state) do
    :config_map
    |> B.build_resource()
    |> B.name("istio")
    |> B.namespace(battery.config.namespace)
    |> B.label("istio.io/rev", "default")
    |> B.data(IstioConfigMapGenerator.materialize(battery, state))
  end
end
