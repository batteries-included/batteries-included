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

  resource(:certificate, battery, state) do
    name = "#{sanitize(battery.type)}-ingress-cert"
    namespace = istio_namespace(state)

    host = Hosts.for_battery(state, battery.type)
    issuer = find_state_resource(state, :certmanager_cluster_issuer, "lets-encrypt")
    spec = build_cert_spec(name, host, issuer)

    :certmanager_certificate
    |> B.build_resource()
    |> B.name(name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_non_empty(spec)
  end

  defp build_cert_spec(_name, host, issuer) when is_nil(host) or is_nil(issuer), do: nil

  defp build_cert_spec(name, host, issuer) do
    issuer_ref = B.issuer_ref(group(issuer), kind(issuer), name(issuer))

    %{
      "dnsNames" => [host],
      "issuerRef" => issuer_ref,
      "secretName" => name
    }
  end
end
