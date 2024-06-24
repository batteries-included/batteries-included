defmodule CommonCore.StateSummary.Hosts do
  @moduledoc false
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.StateSummary

  @default ["127.0.0.1"]

  def control_host(%StateSummary{} = summary) do
    summary |> ip() |> host("control")
  end

  def forgejo_host(%StateSummary{} = summary) do
    summary |> ip() |> host("forgejo")
  end

  def grafana_host(%StateSummary{} = summary) do
    summary |> ip() |> host("grafana")
  end

  def vmselect_host(%StateSummary{} = summary) do
    summary |> ip() |> host("vmselect")
  end

  def vmagent_host(%StateSummary{} = summary) do
    summary |> ip() |> host("vmagent")
  end

  def smtp4dev_host(%StateSummary{} = summary) do
    summary |> ip() |> host("smtp4dev")
  end

  def text_generation_webui_host(%StateSummary{} = summary) do
    summary |> ip() |> host("textgen-webui")
  end

  def keycloak_host(%StateSummary{} = summary) do
    summary |> ip() |> host("keycloak")
  end

  def keycloak_admin_host(%StateSummary{} = summary) do
    summary |> ip() |> host("keycloak-admin")
  end

  def kiali_host(%StateSummary{} = summary) do
    summary |> ip() |> host("kiali")
  end

  def knative_base_host(%StateSummary{} = summary) do
    summary |> ip() |> host("webapp", "user")
  end

  def knative_host(%StateSummary{} = summary, service) do
    namespace = knative_namespace(summary)
    "#{service.name}.#{namespace}.#{knative_base_host(summary)}"
  end

  def notebooks_host(%StateSummary{} = summary) do
    summary |> ip() |> host("notebooks", "user")
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
  def for_battery(summary, :vm_cluster), do: vmselect_host(summary)
  def for_battery(summary, :victoria_metrics), do: vmselect_host(summary)
  def for_battery(summary, :text_generation_webui), do: text_generation_webui_host(summary)
  def for_battery(_summary, _battery_type), do: nil

  defp ip(summary) do
    summary |> ingress_ips() |> List.first()
  end

  defp host(ip, name, group \\ "core")

  defp host(nil, _name, _group), do: ""

  defp host("", _name, _group), do: ""

  defp host(ip, name, group) do
    # Rather than new hostnames for each octet of ips replace with -'s
    # For one this makes lets encrypt happy, and it also speeds
    # up dns look up traversal on the worst case.
    ip = String.replace(ip, ".", "-")

    "#{name}.#{group}.#{ip}.ip.batteriesincl.com"
  end

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
        |> Enum.flat_map(&get_ip_from_ingress_status/1)

      _ ->
        nil
    end)
  end

  defp get_ip_from_ingress_status(%{"ip" => ip} = _ingress), do: [ip]

  defp get_ip_from_ingress_status(%{"hostname" => hostname} = _ingress) do
    erl_host = to_charlist(hostname)

    case :inet.getaddrs(erl_host, :inet) do
      {:ok, addrs} ->
        Enum.map(addrs, &to_string(:inet.ntoa(&1)))

      {:error, _err} ->
        [nil]
    end
  end
end
