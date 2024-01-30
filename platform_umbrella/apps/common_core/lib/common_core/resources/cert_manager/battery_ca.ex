defmodule CommonCore.Resources.BatteryCA do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "battery-ca"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B

  resource(:certmanger_issuer_selfsigned, _battery, state) do
    namespace = base_namespace(state)
    spec = %{"selfSigned" => %{}}

    :certmanger_issuer
    |> B.build_resource()
    |> B.name("battery-root")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:battery_ca_cert, _battery, state) do
    namespace = base_namespace(state)

    spec =
      %{}
      |> Map.put("commonName", "battery-ca")
      |> Map.put("duration", "87600h")
      |> Map.put("isCA", true)
      |> Map.put("issuerRef", %{
        "group" => "cert-manager.io",
        "kind" => "Issuer",
        "name" => "battery-root"
      })
      |> Map.put("privateKey", %{"algorithm" => "ECDSA", "size" => 256})
      |> Map.put("secretName", "battery-ca")
      |> Map.put("subject", %{"organizations" => ["cluster.local", "batteries-included"]})

    :certmanger_certificate
    |> B.build_resource()
    |> B.name("battery-ca")
    |> B.namespace(namespace)
    |> B.spec(spec)
  end

  resource(:battery_ca_cluster_issuer) do
    # This is stupid, but it is what it is.
    #
    # ClusterIssuer takes in a CASpec with a CAConfig
    # that doesn't include a namespace
    #
    # Cert-manager will only look in the namespace that it's
    # running for the secret.
    # NOTE(jdt): the clusterissuer namespace can be specified in the
    # cert-manager config but it's currently the NS it is running in
    spec = %{"ca" => %{"secretName" => "battery-ca"}}

    :certmanger_cluster_issuer
    |> B.build_resource()
    |> B.name("battery-ca")
    |> B.spec(spec)
  end
end
