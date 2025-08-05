defmodule CommonCore.StateSummary.Hosts do
  @moduledoc false
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.StateSummary

  @default ["127.0.0.1"]

  def control_host(%StateSummary{} = summary) do
    summary |> ip() |> host("control")
  end

  def control_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("control")
  end

  def forgejo_host(%StateSummary{} = summary) do
    summary |> ip() |> host("forgejo")
  end

  def forgejo_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("forgejo")
  end

  def grafana_host(%StateSummary{} = summary) do
    summary |> ip() |> host("grafana")
  end

  def grafana_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("grafana")
  end

  def vmselect_host(%StateSummary{} = summary) do
    summary |> ip() |> host("vmselect")
  end

  def vmselect_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("vmselect")
  end

  def vmagent_host(%StateSummary{} = summary) do
    summary |> ip() |> host("vmagent")
  end

  def vmagent_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("vmagent")
  end

  def smtp4dev_host(%StateSummary{} = summary) do
    summary |> ip() |> host("smtp4dev")
  end

  def smtp4dev_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("smtp4dev")
  end

  def keycloak_host(%StateSummary{} = summary) do
    summary |> ip() |> host("keycloak")
  end

  def keycloak_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("keycloak")
  end

  def keycloak_admin_host(%StateSummary{} = summary) do
    summary |> ip() |> host("keycloak-admin")
  end

  def keycloak_admin_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("keycloak-admin")
  end

  def kiali_host(%StateSummary{} = summary) do
    summary |> ip() |> host("kiali")
  end

  def kiali_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("kiali")
  end

  def webapp_base_host(%StateSummary{} = summary) do
    summary |> ip() |> host("webapp")
  end

  def webapp_base_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("webapp")
  end

  def knative_host(%StateSummary{} = summary, service) do
    namespace = knative_namespace(summary)
    "#{service.name}.#{namespace}.#{webapp_base_host(summary)}"
  end

  def knative_hosts(%StateSummary{} = summary),
    do: summary.knative_services |> Enum.reject(& &1.kube_internal) |> Enum.flat_map(&knative_hosts(summary, &1))

  def knative_hosts(%StateSummary{} = summary, service) do
    namespace = knative_namespace(summary)

    summary
    |> webapp_base_hosts()
    |> Enum.map(fn base -> "#{service.name}.#{namespace}.#{base}" end)
  end

  def traditional_host(%StateSummary{} = _summary, %{additional_hosts: add_hosts}) when length(add_hosts) > 0,
    do: List.first(add_hosts)

  def traditional_host(%StateSummary{} = summary, service) do
    namespace = traditional_namespace(summary)
    "#{service.name}.#{namespace}.#{webapp_base_host(summary)}"
  end

  def traditional_hosts(%StateSummary{} = summary),
    do: Enum.flat_map(summary.traditional_services, &traditional_hosts(summary, &1))

  def traditional_hosts(%StateSummary{} = summary, service) do
    namespace = traditional_namespace(summary)

    hosts =
      summary
      |> webapp_base_hosts()
      |> Enum.map(fn base -> "#{service.name}.#{namespace}.#{base}" end)

    hosts ++ Map.get(service, :additional_hosts, [])
  end

  def notebooks_host(%StateSummary{} = summary) do
    summary |> ip() |> host("notebooks")
  end

  def notebooks_hosts(%StateSummary{} = summary) do
    summary |> ingress_ips() |> hosts("notebooks")
  end

  # NOTE: This isn't exclusive - some batteries don't have host mappings, some may have multiple in the future.
  # This should probably be revisited / revised in the future.
  @spec for_battery(StateSummary.t(), atom()) :: String.t() | nil
  def for_battery(summary, battery_type)

  def for_battery(summary, :battery_core), do: control_host(summary)
  def for_battery(summary, :forgejo), do: forgejo_host(summary)
  def for_battery(summary, :grafana), do: grafana_host(summary)
  def for_battery(summary, :keycloak), do: keycloak_host(summary)
  def for_battery(summary, :kiali), do: kiali_host(summary)
  def for_battery(summary, :notebooks), do: notebooks_host(summary)
  def for_battery(summary, :smtp4dev), do: smtp4dev_host(summary)
  def for_battery(summary, :vm_agent), do: vmagent_host(summary)
  def for_battery(summary, :victoria_metrics), do: vmselect_host(summary)
  def for_battery(_summary, _battery_type), do: nil

  # NOTE: This isn't exclusive - some batteries don't have host mappings, some may have multiple in the future.
  # This should probably be revisited / revised in the future.
  @spec hosts_for_battery(StateSummary.t(), atom()) :: list(String.t())
  def hosts_for_battery(summary, battery_type)

  def hosts_for_battery(summary, :battery_core), do: control_hosts(summary)
  def hosts_for_battery(summary, :forgejo), do: forgejo_hosts(summary)
  def hosts_for_battery(summary, :grafana), do: grafana_hosts(summary)
  def hosts_for_battery(summary, :keycloak), do: keycloak_hosts(summary)
  def hosts_for_battery(summary, :kiali), do: kiali_hosts(summary)
  def hosts_for_battery(summary, :notebooks), do: notebooks_hosts(summary)
  def hosts_for_battery(summary, :smtp4dev), do: smtp4dev_hosts(summary)
  def hosts_for_battery(summary, :vm_agent), do: vmagent_hosts(summary)
  def hosts_for_battery(summary, :victoria_metrics), do: vmselect_hosts(summary)
  def hosts_for_battery(summary, :knative), do: knative_hosts(summary)
  def hosts_for_battery(summary, :traditional_services), do: traditional_hosts(summary)
  def hosts_for_battery(_summary, _battery_type), do: nil

  defp ip(summary) do
    summary |> ingress_ips() |> List.first()
  end

  defp host(ip, name)

  defp host(nil, _name), do: ""

  defp host("", _name), do: ""

  defp host(ip, name) do
    # Rather than new hostnames for each octet of ips replace with -'s
    # For one this makes lets encrypt happy, and it also speeds
    # up dns look up traversal on the worst case.
    ip = String.replace(ip, ".", "-")

    "#{name}.#{ip}.batrsinc.co"
  end

  defp hosts(ips, name)
  defp hosts([], _name), do: []
  defp hosts(ips, name), do: Enum.map(ips, &host(&1, name))

  defp ingress_ips(%StateSummary{} = summary) do
    istio_namespace = istio_namespace(summary)
    # the name of the ingress service.
    # We aren't using the Gateway name or the istio tag here
    # We are using metadata.name for service selection
    ingress_name = "istio-ingressgateway"

    summary.kube_state
    |> Map.get(:service, [])
    |> ingress_ips_from_services(istio_namespace, ingress_name)
    |> Enum.sort(:asc)
  end

  defp ingress_ips_from_services(services, istio_namespace, ingress_name) do
    Enum.find_value(services, @default, fn
      %{
        "metadata" => %{"name" => ^ingress_name, "namespace" => ^istio_namespace},
        "status" => %{"loadBalancer" => %{"ingress" => values}}
      } ->
        values
        |> Enum.filter(fn pos -> pos != nil end)
        |> Enum.flat_map(&get_ips_from_ingress_status/1)

      _ ->
        nil
    end)
  end

  defp get_ips_from_ingress_status(%{"ip" => ip} = _ingress), do: [ip]

  defp get_ips_from_ingress_status(%{"hostname" => hostname} = _ingress) do
    erl_host = to_charlist(hostname)

    case :inet.getaddrs(erl_host, :inet) do
      {:ok, addrs} ->
        Enum.map(addrs, &to_string(:inet.ntoa(&1)))

      {:error, _err} ->
        [nil]
    end
  end
end
