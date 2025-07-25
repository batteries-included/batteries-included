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

  resource(:crd_authorizationpolicies_security_io) do
    YamlElixir.read_all_from_string!(get_resource(:authorizationpolicies_security_istio_io))
  end

  resource(:crd_destinationrules_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:destinationrules_networking_istio_io))
  end

  resource(:crd_envoyfilters_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:envoyfilters_networking_istio_io))
  end

  resource(:crd_gateways_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:gateways_networking_istio_io))
  end

  resource(:crd_peerauthentications_security_io) do
    YamlElixir.read_all_from_string!(get_resource(:peerauthentications_security_istio_io))
  end

  resource(:crd_proxyconfigs_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:proxyconfigs_networking_istio_io))
  end

  resource(:crd_requestauthentications_security_io) do
    YamlElixir.read_all_from_string!(get_resource(:requestauthentications_security_istio_io))
  end

  resource(:crd_serviceentries_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:serviceentries_networking_istio_io))
  end

  resource(:crd_sidecars_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:sidecars_networking_istio_io))
  end

  resource(:crd_telemetries_telemetry_io) do
    YamlElixir.read_all_from_string!(get_resource(:telemetries_telemetry_istio_io))
  end

  resource(:crd_virtualservices_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:virtualservices_networking_istio_io))
  end

  resource(:crd_wasmplugins_extensions_io) do
    YamlElixir.read_all_from_string!(get_resource(:wasmplugins_extensions_istio_io))
  end

  resource(:crd_workloadentries_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:workloadentries_networking_istio_io))
  end

  resource(:crd_workloadgroups_networking_io) do
    YamlElixir.read_all_from_string!(get_resource(:workloadgroups_networking_istio_io))
  end

  resource(:config_map_main, battery, state) do
    :config_map
    |> B.build_resource()
    |> B.name("istio")
    |> B.namespace(battery.config.namespace)
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.data(IstioConfigMapGenerator.materialize(battery, state))
  end
end
