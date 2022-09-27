defmodule KubeResources.GrafanaDashboards do
  alias KubeExt.Builder, as: B

  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias K8s.Resource
  alias KubeResources.GrafanaDashboardClient
  alias KubeResources.MonitoringSettings

  @dashboards_configmap "grafana-dashboards"
  @app_name "grafana"

  def dashboards(config) do
    Services.all_including_config()
    |> Enum.map(fn %BaseService{} = bs ->
      config
      |> dashboards(bs.service_type)
      |> Enum.map(fn {path, r} -> {path, B.owner_label(r, bs.id)} end)
      |> Enum.into(%{})
    end)
    |> Enum.reduce(%{}, &Map.merge/2)
  end

  def dashboards(config, :kube_monitoring) do
    %{
      "/grafana-dashboard-definitions/kube/#{grafana_dashboard_name(7249)}" =>
        dashboard_configmap_from_grafana_id(config, 7249),
      "/grafana-dashboard-definitions/kube/#{grafana_dashboard_name(6417)}" =>
        dashboard_configmap_from_grafana_id(config, 6417),
      "/grafana-dashboard-definitions/kube/#{grafana_dashboard_name(1860)}" =>
        dashboard_configmap_from_grafana_id(config, 1860)
    }
  end

  def dashboards(config, :postgres_operator) do
    %{
      "/grafana-dashboard-definitions/database/#{grafana_dashboard_name(9628)}" =>
        dashboard_configmap_from_grafana_id(config, 9628)
    }
  end

  def dashboards(config, :istio) do
    %{
      "/grafana-dashboard-definitions/network/#{grafana_dashboard_name(7645)}" =>
        dashboard_configmap_from_grafana_id(config, 7645),
      "/grafana-dashboard-definitions/network/#{grafana_dashboard_name(7630)}" =>
        dashboard_configmap_from_grafana_id(config, 7630),
      "/grafana-dashboard-definitions/network/#{grafana_dashboard_name(7636)}" =>
        dashboard_configmap_from_grafana_id(config, 7636)
    }
  end

  def dashboards(_config, _service_type), do: %{}

  def grafana_dashboard_name(id), do: "grafana-dashboard-#{id}"

  def dashboard_configmap_from_grafana_id(config, id) do
    namespace = MonitoringSettings.namespace(config)

    dash = get_updated_dashboard(id)

    B.build_resource(:config_map)
    |> B.name(grafana_dashboard_name(id))
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> Map.put("data", %{
      "dashboard.json" => Jason.encode!(dash)
    })
  end

  def get_updated_dashboard(id) do
    id
    |> GrafanaDashboardClient.dashboard()
    |> set_all_templated_prom()
    |> extract_prometheus_templated_names()
    |> extract_prometheus_input_names()
    |> set_unset_inputs()
  end

  def set_all_templated_prom(dashboard) do
    dashboard
    |> Map.put_new("templating", %{"list" => []})
    |> update_in(~w(templating list), fn list ->
      list = list || []
      Enum.map(list, &set_template_datasource/1)
    end)
  end

  def extract_prometheus_templated_names(dash) do
    %{
      dash: dash,
      # These are the templated variable names that
      # don't need to be set even if they are in
      # the __input list.
      templated_names:
        dash
        |> get_in(~w(templating list))
        |> Enum.filter(fn t -> Map.get(t, "type", nil) == "query" end)
        |> Enum.map(fn t -> Map.get(t, "name") end)
        |> Enum.into([])
    }
  end

  def extract_prometheus_input_names(%{dash: dash, templated_names: templated_names}) do
    %{
      dash: dash,
      prometheus_input_names:
        dash
        |> Map.get("__inputs", [])
        |> Enum.filter(fn input -> Map.get(input, "pluginId", nil) == "prometheus" end)
        |> Enum.map(fn input -> Map.get(input, "name") end)
        |> Enum.reject(fn name -> Enum.member?(templated_names, name) end)
    }
  end

  def set_unset_inputs(%{dash: dash, prometheus_input_names: prometheus_input_names}) do
    prometheus_input_names
    |> Enum.reduce(dash, fn potential_input_name, acc ->
      recursive_update(acc, potential_input_name, "battery-prometheus")
    end)
    |> Map.drop(["__inputs"])
    |> Map.drop(["__requires"])
  end

  def recursive_update(%{} = dash_object, input_name, new_value) do
    dash_object
    |> Enum.map(fn {key, value} ->
      {key,
       value
       |> maybe_update(input_name, new_value)
       |> recursive_update(input_name, new_value)}
    end)
    |> Enum.into(%{})
  end

  def recursive_update(obj_list, input_name, new_value) when is_list(obj_list) do
    Enum.map(obj_list, fn o -> recursive_update(o, input_name, new_value) end)
  end

  def recursive_update(value, _, _), do: value

  def maybe_update(current_value, input_name, new_value) when is_binary(current_value) do
    p_name = "${#{input_name}}"
    name = "$#{input_name}"
    current_value |> String.replace(p_name, new_value) |> String.replace(name, new_value)
  end

  def maybe_update(current_value, _, _), do: current_value

  def set_template_datasource(%{"query" => "prometheus"} = template) do
    Map.put(template, "current", %{
      "text" => "prometheus",
      "value" => "prometheus"
    })
  end

  def set_template_datasource(template), do: template

  def add_volumes(volumes, dashboards) do
    dash_volumes =
      Enum.map(dashboards, fn {_path, dashboard} ->
        %{
          "name" => Resource.name(dashboard),
          "configMap" => %{"name" => Resource.name(dashboard)}
        }
      end)

    [
      %{
        "configMap" => %{
          "name" => @dashboards_configmap
        },
        "name" => @dashboards_configmap
      }
      | volumes
    ] ++ dash_volumes
  end
end
