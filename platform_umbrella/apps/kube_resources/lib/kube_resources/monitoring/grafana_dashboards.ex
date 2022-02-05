defmodule KubeResources.GrafanaDashboards do
  alias KubeExt.Builder, as: B

  alias ControlServer.Services
  alias ControlServer.Services.BaseService
  alias K8s.Resource
  alias KubeResources.GrafanaDashboardClient
  alias KubeResources.MonitoringSettings

  @dashboards_configmap "grafana-dashboards"
  @app_name "grafana"
  @possible_providers [
    %{
      "folder" => "Default",
      "name" => "0",
      "options" => %{
        "path" => "/grafana-dashboard-definitions/0"
      },
      "disableDeletion" => false,
      "allowUiUpdates" => false,
      "orgId" => 1,
      "type" => "file"
    },
    %{
      "folder" => "Databases",
      "name" => "1",
      "options" => %{
        "path" => "/grafana-dashboard-definitions/1"
      },
      "disableDeletion" => false,
      "allowUiUpdates" => false,
      "orgId" => 1,
      "type" => "file"
    },
    %{
      "folder" => "Kubernetes",
      "name" => "2",
      "options" => %{
        "path" => "/grafana-dashboard-definitions/2"
      },
      "disableDeletion" => false,
      "allowUiUpdates" => false,
      "orgId" => 1,
      "type" => "file"
    }
  ]

  def add_dashboards(deployment, config) do
    dashboards = dashboards(config)

    deployment =
      deployment
      |> update_in(~w(spec template spec volumes ), fn volumes ->
        add_volumes(volumes, dashboards)
      end)
      |> update_in(~w(spec template spec containers ), fn containers ->
        add_volume_mounts(containers, dashboards)
      end)

    {deployment, [dashboard_sources_config(config)] ++ Map.values(dashboards)}
  end

  def dashboards(config) do
    Services.list_base_services()
    |> Enum.map(fn %BaseService{} = bs -> bs.service_type end)
    |> Enum.map(fn service_type -> dashboards(config, service_type) end)
    |> Enum.reduce(%{}, fn element, acc -> Map.merge(acc, element) end)
  end

  def dashboards(config, :monitoring) do
    %{
      "/grafana-dashboard-definitions/2/#{grafana_dashboard_name(11_455)}" =>
        dashboard_configmap_from_grafana_id(config, 11_455)
    }
  end

  def dashboards(config, :database) do
    %{
      "/grafana-dashboard-definitions/1/#{grafana_dashboard_name(9628)}" =>
        dashboard_configmap_from_grafana_id(config, 9628)
    }
  end

  def dashboards(_config, _service_type), do: %{}

  def dashboard_configmap_from_grafana_id(config, id) do
    namespace = MonitoringSettings.namespace(config)

    raw_dash =
      id
      |> GrafanaDashboardClient.dashboard()
      |> Map.put_new("templating", %{"list" => []})
      |> update_in(~w(templating list), fn list ->
        list = list || []
        Enum.map(list, &set_template_datasource/1)
      end)

    B.build_resource(:config_map)
    |> B.name(grafana_dashboard_name(id))
    |> B.namespace(namespace)
    |> B.app_labels(@app_name)
    |> Map.put("data", %{
      "dashboard.json" => Jason.encode!(raw_dash)
    })
  end

  def grafana_dashboard_name(id), do: "grafana-dashboard-#{id}"

  def set_template_datasource(%{"query" => "prometheus"} = template) do
    Map.put(template, "current", %{
      "text" => "battery-prometheus",
      "value" => "battery-prometheus"
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

  def add_volume_mounts(containers, dashboards) when is_list(containers) do
    Enum.map(containers, fn container -> add_volume_mounts(container, dashboards) end)
  end

  def add_volume_mounts(%{"volumeMounts" => volume_mounts} = container, dashboards) do
    dash_volume_mounts =
      Enum.map(dashboards, fn {path, config} ->
        %{
          "mountPath" => path,
          "name" => Resource.name(config),
          "readOnly" => true
        }
      end)

    volume_mounts =
      [
        # Add the config to list locations
        %{
          "mountPath" => "/etc/grafana/provisioning/dashboards",
          "name" => @dashboards_configmap,
          "readOnly" => false
        }

        # The rest of the existing volume mounts
        | volume_mounts
      ] ++ dash_volume_mounts

    %{container | "volumeMounts" => volume_mounts}
  end

  def dashboard_sources_config(config) do
    namespace = MonitoringSettings.namespace(config)

    file_contents =
      Ymlr.Encoder.to_s!(%{
        "apiVersion" => 1,
        "providers" => @possible_providers
      })

    B.build_resource(:config_map)
    |> B.app_labels(@app_name)
    |> B.name(@dashboards_configmap)
    |> B.namespace(namespace)
    |> Map.put("data", %{"dashboards.yaml" => file_contents})
  end
end
