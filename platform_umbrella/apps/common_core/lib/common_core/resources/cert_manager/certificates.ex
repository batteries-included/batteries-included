defmodule CommonCore.Resources.CertManager.Certificates do
  @moduledoc """
  Responsible for creating cert_manager `Certificate` resources for installed batteries.
  """

  import CommonCore.StateSummary.Batteries

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Resources.CertManager.Certificates.Cert
  alias CommonCore.StateSummary

  @cert_manager_disabled_batteries ~w()a

  def materialize(%SystemBattery{} = _battery, %StateSummary{} = state) do
    state
    |> by_type()
    |> Enum.reject(fn {type, _battery} -> type in @cert_manager_disabled_batteries end)
    |> Enum.map(fn {_type, battery} -> Cert.materialize(battery, state) end)
    |> Enum.reduce(%{}, &Map.merge/2)
  end
end

defmodule CommonCore.Resources.CertManager.Certificates.Cert do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "certificates"

  import CommonCore.Resources.FieldAccessors
  import CommonCore.Resources.ProxyUtils, only: [sanitize: 1]
  import CommonCore.StateSummary.FromKubeState, only: [find_state_resource: 3]
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary.Hosts

  resource(:certificate, %{type: type} = _battery, state) do
    name = "#{sanitize(type)}-ingress-cert"
    namespace = istio_namespace(state)

    spec = spec(name, state, type)

    :certmanager_certificate
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.label("battery/gateway", "istio-ingressgateway")
    |> B.label("battery/certificate-for", Atom.to_string(type))
    |> B.spec(spec)
    |> F.require_non_empty(spec)
  end

  defp spec(name, state, :knative) do
    hosts = Enum.flat_map(state.knative_services, &Hosts.knative_hosts(state, &1))
    issuer = find_state_resource(state, :certmanager_cluster_issuer, "lets-encrypt")
    build_cert_spec(name, hosts, issuer)
  end

  defp spec(name, state, :traditional_services) do
    hosts = Enum.flat_map(state.traditional_services, &Hosts.traditional_hosts(state, &1))
    issuer = find_state_resource(state, :certmanager_cluster_issuer, "lets-encrypt")
    build_cert_spec(name, hosts, issuer)
  end

  defp spec(name, state, battery_type) do
    host = Hosts.hosts_for_battery(state, battery_type)
    issuer = find_state_resource(state, :certmanager_cluster_issuer, "lets-encrypt")
    build_cert_spec(name, host, issuer)
  end

  defp build_cert_spec(_name, hosts, issuer) when is_nil(hosts) or is_nil(issuer), do: nil

  defp build_cert_spec(_name, [] = _hosts, _issuer), do: nil

  defp build_cert_spec(name, hosts, issuer) do
    issuer_ref = B.issuer_ref(group(issuer), kind(issuer), name(issuer))

    %{
      "dnsNames" => hosts,
      "issuerRef" => issuer_ref,
      "secretName" => name
    }
  end
end
