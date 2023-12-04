defmodule CommonCore.StateSummary.Hosts do
  @moduledoc false
  import CommonCore.StateSummary.Namespaces

  alias CommonCore.StateSummary

  @default ["127.0.0.1"]

  def control_host(%StateSummary{} = summary) do
    summary |> ip() |> host("control")
  end

  def gitea_host(%StateSummary{} = summary) do
    summary |> ip() |> host("gitea")
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
  @spec for_battery(StateSummary.t(), atom()) :: String.t()
  def for_battery(summary, battery_type)

  # HACK(jdt): fix this!
  def for_battery(_summary, :battery_core), do: "control.127.0.0.1.ip.batteriesincl.com:4000"
  def for_battery(summary, :gitea), do: gitea_host(summary)
  def for_battery(summary, :grafana), do: grafana_host(summary)
  def for_battery(summary, :keycloak), do: keycloak_host(summary)
  def for_battery(summary, :kiali), do: kiali_host(summary)
  def for_battery(summary, :notebooks), do: notebooks_host(summary)
  def for_battery(summary, :smtp4dev), do: smtp4dev_host(summary)
  def for_battery(summary, :vm_agent), do: vmagent_host(summary)
  def for_battery(summary, :vm_cluster), do: vmselect_host(summary)
  def for_battery(summary, :victoria_metrics), do: vmselect_host(summary)
  def for_battery(_summary, _battery_type), do: nil

  defp ip(summary) do
    summary |> ingress_ips() |> List.first()
  end

  defp host(ip, name, group \\ "core") do
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
    |> ingress_ips_from_service(istio_namespace, ingress_name)
    |> Enum.sort(:asc)
  end

  defp ingress_ips_from_service(services, istio_namespace, ingress_name) do
    Enum.find_value(services, @default, fn
      %{
        "metadata" => %{"name" => ^ingress_name, "namespace" => ^istio_namespace},
        "status" => %{"loadBalancer" => %{"ingress" => values}}
      } ->
        values
        |> Enum.filter(fn pos -> pos != nil end)
        |> Enum.map(fn pos -> Map.get(pos, "ip") end)

      _ ->
        nil
    end)
  end
end
