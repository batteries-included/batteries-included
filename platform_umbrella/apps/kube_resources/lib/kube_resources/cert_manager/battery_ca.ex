defmodule KubeResources.BatteryCA do
  use KubeExt.ResourceGenerator

  import CommonCore.SystemState.Namespaces
  alias KubeExt.Builder, as: B

  @app_name "istio_ca"

  resource(:certmanger_issuer_selfsigned, _battery, state) do
    namespace = base_namespace(state)
    spec = %{"selfSigned" => %{}}

    B.build_resource(:certmanger_issuer)
    |> B.name("battery-root")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
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

    B.build_resource(:certmanger_certificate)
    |> B.name("battery-ca")
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
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
    spec = %{"ca" => %{"secretName" => "battery-ca"}}

    B.build_resource(:certmanger_cluster_issuer)
    |> B.name("battery-ca")
    |> B.app_labels(@app_name)
    |> B.spec(spec)
  end
end
