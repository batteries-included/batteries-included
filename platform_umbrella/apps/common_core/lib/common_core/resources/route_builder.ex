defmodule CommonCore.Resources.RouteBuilder do
  @moduledoc false
  import CommonCore.StateSummary.Namespaces
  import CommonCore.Util.String

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
    |> new_httproute_spec_for_hosts(battery, state)
  end

  @spec new_httproute_spec_for_hosts(list(binary()), SystemBattery.t(), StateSummary.t()) :: map()
  def new_httproute_spec_for_hosts(hosts, battery, state) do
    %{
      "parentRefs" => get_parent_ref(battery, state),
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

  @spec valid?(map()) :: boolean()
  def valid?(spec) do
    spec
    |> Map.get("hostnames")
    |> Enum.all?(&Hosts.valid_host?(&1))
  end

  defp get_parent_ref(battery, state) do
    istio_ns = istio_namespace(state)

    if SSL.ssl_enabled?(state) do
      state
      |> Batteries.hosts_by_battery_type()
      |> Map.get(battery.type, [])
      |> Enum.with_index()
      |> Enum.map(fn {_host, ix} ->
        %{
          "name" => "istio-ingressgateway",
          "namespace" => istio_ns,
          "sectionName" => "https-#{kebab_case(battery.type)}-#{ix}"
        }
      end)
    else
      [%{"name" => "istio-ingressgateway", "namespace" => istio_ns}]
    end
  end
end
