defmodule CommonCore.StateSummary.TraditionalServices do
  @moduledoc """
    Utilities for manipulating and querying traditional service information from a state summary.
  """
  alias CommonCore.Port
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts
  alias CommonCore.TraditionalServices.Service

  @doc """
  Generate a map of hosts to ports for traditional services
  """
  @spec hosts_and_ports_by_name(StateSummary.t()) :: map()
  def hosts_and_ports_by_name(%StateSummary{traditional_services: services} = state) do
    Map.new(services, &hosts_and_ports_for_service(state, &1))
  end

  @doc """
  Generate a map of external hosts to ports for traditional services

  Filters out internal services and services without ports.
  """
  @spec external_hosts_and_ports_by_name(StateSummary.t()) :: map()
  def external_hosts_and_ports_by_name(%StateSummary{traditional_services: services} = state) do
    services
    |> Enum.reject(&internal_or_portless/1)
    |> Map.new(&hosts_and_ports_for_service(state, &1))
  end

  @spec hosts_and_ports_for_service(StateSummary.t(), Service.t()) :: {String.t(), {list(String.t()), list(Port.t())}}
  defp hosts_and_ports_for_service(state, %{ports: ports, name: name} = svc),
    do: {name, {Hosts.traditional_hosts(state, svc), ports}}

  defp internal_or_portless(%{kube_internal: true}), do: true
  defp internal_or_portless(%{ports: []}), do: true
  defp internal_or_portless(%{ports: nil}), do: true
  defp internal_or_portless(_), do: false
end
