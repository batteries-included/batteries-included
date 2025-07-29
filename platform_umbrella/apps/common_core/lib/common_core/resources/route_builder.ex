defmodule CommonCore.Resources.RouteBuilder do
  @moduledoc false
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Resources.ProxyUtils, as: PU
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Batteries
  alias CommonCore.StateSummary.Hosts
  alias CommonCore.StateSummary.SSL

  @spec new_httproute_spec(SystemBattery.t(), StateSummary.t()) :: map()
  def new_httproute_spec(battery, state) do
    state
    |> Hosts.hosts_for_battery(battery.type)
    |> new_httproute_spec_for_hosts(state)
  end

  @spec new_httproute_spec_for_hosts(list(binary()), StateSummary.t()) :: map()
  def new_httproute_spec_for_hosts(hosts, state) do
    istio_ns = istio_namespace(state)

    %{
      "parentRefs" => [%{"name" => "istio-ingressgateway", "namespace" => istio_ns}],
      "hostnames" => hosts,
      "rules" => []
    }
  end

  @spec add_oauth2_proxy_rule(map(), SystemBattery.t(), StateSummary.t()) :: map()
  def add_oauth2_proxy_rule(spec, battery, state) do
    if Batteries.sso_installed?(state) do
      # prepend
      update_in(
        spec,
        ["rules"],
        &([
            %{
              "matches" => [%{"path" => %{"type" => "PathPrefix", "value" => "/oauth2"}}],
              "backendRefs" => [%{"name" => PU.service_name(battery), "port" => PU.port(battery)}]
            }
          ] ++ &1)
      )
    else
      spec
    end
  end

  @spec add_backend(map(), binary(), non_neg_integer()) :: map()
  def add_backend(spec, name, port) do
    update_in(spec, ["rules"], &(&1 ++ [%{"backendRefs" => [%{"name" => name, "port" => port}]}]))
  end

  @spec add_prefixed_backend(map(), binary(), binary(), non_neg_integer()) :: map()
  def add_prefixed_backend(spec, prefix, name, port) do
    update_in(
      spec,
      ["rules"],
      &(&1 ++
          [
            %{
              "matches" => [%{"path" => %{"type" => "PathPrefix", "value" => prefix}}],
              "backendRefs" => [%{"name" => name, "port" => port}]
            }
          ])
    )
  end

  @spec maybe_https_redirect(map(), StateSummary.t()) :: map()
  def maybe_https_redirect(spec, state) do
    if SSL.ssl_enabled?(state) do
      update_in(
        spec,
        ["rules"],
        &([
            %{
              "filters" => [
                %{"type" => "RequestRedirect", "requestRedirect" => %{"scheme" => "http", "statusCode" => 301}}
              ]
            }
          ] ++ &1)
      )
    else
      spec
    end
  end
end
