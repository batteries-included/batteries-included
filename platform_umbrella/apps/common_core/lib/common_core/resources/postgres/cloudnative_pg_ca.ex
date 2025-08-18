defmodule CommonCore.Resources.CloudnativePGCA do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "cnpg-ca"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:cnpg_cert, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("commonName", "cnpg-ca")
      # ~10y
      |> Map.put("duration", "87600h")
      # ~30d
      |> Map.put("renewBefore", "720h")
      |> Map.put("isCA", true)
      |> Map.put("issuerRef", %{
        "group" => "cert-manager.io",
        "kind" => "ClusterIssuer",
        "name" => "battery-ca"
      })
      |> Map.put("privateKey", %{"algorithm" => "ECDSA", "size" => 256})
      |> Map.put("secretName", "cnpg-ca")
      |> Map.put("secretTemplate", %{} |> B.managed_indirect_labels() |> B.label("cnpg.io/reload", ""))
      |> Map.put("subject", %{"organizations" => ["cluster.local", "batteries-included", "cnpg"]})

    :certmanager_certificate
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.namespace(namespace)
    |> B.spec(spec)
    |> F.require_battery(state, :battery_ca)
  end

  resource(:cnpg_cluster_issuer, _battery, state) do
    spec = %{"ca" => %{"secretName" => "cnpg-ca"}}

    :certmanager_cluster_issuer
    |> B.build_resource()
    |> B.name(@app_name)
    |> B.spec(spec)
    |> F.require_battery(state, :battery_ca)
  end
end
