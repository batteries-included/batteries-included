defmodule CommonCore.Resources.Istio.Gateways do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "istio-gateways"

  import CommonCore.Resources.ProxyUtils, only: [sanitize: 1]
  import CommonCore.StateSummary.Batteries, only: [hosts_by_battery_type: 1]
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F
  alias CommonCore.StateSummary.TraditionalServices

  resource(:gateway, _battery, state) do
    namespace = istio_namespace(state)

    ssl_enabled? = CommonCore.StateSummary.SSL.ssl_enabled?(state)

    battery_servers =
      state
      |> hosts_by_battery_type()
      |> Enum.flat_map(fn {type, hosts} -> build_battery_servers(type, hosts, ssl_enabled?) end)

    traditional_service_servers =
      state
      |> TraditionalServices.external_hosts_and_ports_by_name()
      |> Enum.flat_map(fn {_, {host, ports}} -> build_server_for_traditional_service(host, ports, ssl_enabled?) end)

    servers = battery_servers ++ traditional_service_servers

    spec = %{
      selector: %{istio: "ingressgateway"},
      servers: servers
    }

    :istio_gateway
    |> B.build_resource()
    |> B.name("ingressgateway")
    |> B.namespace(namespace)
    |> B.label("istio", "ingressgateway")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
    |> F.require_non_empty(servers)
  end

  defp build_battery_servers(:forgejo = type, hosts, ssl_enabled?),
    do: [forgejo_ssh_server(hosts)] ++ web_servers(sanitize(type), hosts, ssl_enabled?)

  defp build_battery_servers(type, hosts, ssl_enabled?), do: web_servers(sanitize(type), hosts, ssl_enabled?)

  defp web_servers(type, hosts, true = _ssl_enabled?) do
    [
      %{
        port: %{number: 443, name: "https-#{type}", protocol: "HTTPS"},
        tls: %{mode: "SIMPLE", credentialName: "#{type}-ingress-cert"},
        hosts: hosts
      },
      %{
        port: %{number: 80, name: "http2-#{sanitize(type)}", protocol: "HTTP"},
        hosts: hosts
      }
    ]
  end

  defp web_servers(type, hosts, false = _ssl_enabled?) do
    [
      %{
        port: %{number: 80, name: "http2-#{sanitize(type)}", protocol: "HTTP"},
        hosts: hosts
      }
    ]
  end

  defp forgejo_ssh_server(hosts), do: %{port: %{number: 22, name: "ssh-forgejo", protocol: "TCP"}, hosts: hosts}

  defp build_server_for_traditional_service(_hosts, ports, _ssl_enabled?) when is_nil(ports) or ports == [], do: []

  defp build_server_for_traditional_service(hosts, ports, ssl_enabled?) do
    Enum.flat_map(ports, &build_server_for_traditional_service_port(hosts, &1, ssl_enabled?))
  end

  defp build_server_for_traditional_service_port(hosts, %{protocol: protocol} = port, true = _ssl_enabled?)
       when protocol in [:http, :http2] do
    [
      %{
        port: %{number: 443, name: "#{port.name}-https", protocol: "HTTPS"},
        tls: %{mode: "SIMPLE", credentialName: "traditional-services-ingress-cert"},
        hosts: hosts
      },
      %{
        port: %{number: 80, name: "#{port.name}-http", protocol: normalize_protocol(port.protocol)},
        hosts: hosts
      }
    ]
  end

  defp build_server_for_traditional_service_port(hosts, %{protocol: :tcp} = port, true = _ssl_enabled?) do
    [%{port: %{number: port.number, name: port.name, protocol: "TCP"}, hosts: hosts}]
  end

  defp build_server_for_traditional_service_port(hosts, %{protocol: protocol} = port, false = _ssl_enabled?)
       when protocol in [:http, :http2] do
    [
      %{
        port: %{number: 80, name: port.name, protocol: normalize_protocol(port.protocol)},
        hosts: hosts
      }
    ]
  end

  defp build_server_for_traditional_service_port(hosts, port, false = _ssl_enabled?) do
    [
      %{
        port: %{number: port.number, name: port.name, protocol: normalize_protocol(port.protocol)},
        hosts: hosts
      }
    ]
  end

  defp normalize_protocol(proto), do: String.upcase(Atom.to_string(proto))
end
