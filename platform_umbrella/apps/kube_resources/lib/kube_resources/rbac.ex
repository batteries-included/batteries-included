defmodule KubeResources.RBAC do
  @proxy_image "quay.io/brancz/kube-rbac-proxy"
  @proxy_version "v0.11.0"

  @tls_suites ~w[
    TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
    TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
    TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
    TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
    TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
    TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
  ]

  def proxy_container(upstream_url, port, port_name, name \\ "kube-rbac-proxy") do
    name
    |> base()
    |> Map.put("args", [
      "--logtostderr",
      "--secure-listen-address=:#{port}",
      "--tls-cipher-suites=#{suites()}",
      "--upstream=#{upstream_url}",
      "-v9"
    ])
    |> Map.put("ports", [
      %{
        "containerPort" => port,
        "name" => port_name
      }
    ])
  end

  def host_proxy_container(upstream_url, port, port_name, name \\ "kube-rbac-proxy") do
    name
    |> base()
    |> Map.put("args", [
      "--logtostderr",
      "--secure-listen-address=[$(IP)]:#{port}",
      "--tls-cipher-suites=#{suites()}",
      "--upstream=#{upstream_url}",
      "-v9"
    ])
    |> Map.put("env", [
      %{
        "name" => "IP",
        "valueFrom" => %{
          "fieldRef" => %{
            "fieldPath" => "status.podIP"
          }
        }
      }
    ])
    |> Map.put("ports", [
      %{
        "containerPort" => port,
        "hostPort" => port,
        "name" => port_name
      }
    ])
  end

  defp base(name) do
    %{
      "image" => "#{@proxy_image}:#{@proxy_version}",
      "name" => name,
      "resources" => %{
        "limits" => %{
          "cpu" => "20m",
          "memory" => "40Mi"
        },
        "requests" => %{
          "cpu" => "10m",
          "memory" => "20Mi"
        }
      },
      "securityContext" => %{
        "runAsGroup" => 65_532,
        "runAsNonRoot" => true,
        "runAsUser" => 65_532
      }
    }
  end

  def suites do
    Enum.join(@tls_suites, ",")
  end
end
