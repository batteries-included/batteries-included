defmodule CommonCore.Resources.KubeDashboards do
  @moduledoc false
  use CommonCore.IncludeResource,
    dashboard_15757: "priv/raw_files/kube_monitoring/dashboard_15757.json",
    dashboard_15758: "priv/raw_files/kube_monitoring/dashboard_15758.json",
    dashboard_15759: "priv/raw_files/kube_monitoring/dashboard_15759.json",
    dashboard_15760: "priv/raw_files/kube_monitoring/dashboard_15760.json"

  use CommonCore.Resources.ResourceGenerator, app_name: "kube-dashboard"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:config_map_dashboard_15760, _battery, state) do
    namespace = core_namespace(state)
    data = %{"dashboard_15760.json" => get_resource(:dashboard_15760)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-dashboard-15760")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_dashboard", "1")
    |> B.label("grafana_folder", @app_name)
    |> F.require_battery(state, :grafana)
  end

  resource(:config_map_dashboard_15759, _battery, state) do
    namespace = core_namespace(state)
    data = %{"dashboard_15759.json" => get_resource(:dashboard_15759)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-dashboard-15759")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_dashboard", "1")
    |> B.label("grafana_folder", @app_name)
    |> F.require_battery(state, :grafana)
  end

  resource(:config_map_dashboard_15758, _battery, state) do
    namespace = core_namespace(state)
    data = %{"dashboard_15758.json" => get_resource(:dashboard_15758)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-dashboard-15758")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_dashboard", "1")
    |> B.label("grafana_folder", @app_name)
    |> F.require_battery(state, :grafana)
  end

  resource(:config_map_dashboard_15757, _battery, state) do
    namespace = core_namespace(state)
    data = %{"dashboard_15757.json" => get_resource(:dashboard_15757)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-dashboard-15757")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_dashboard", "1")
    |> B.label("grafana_folder", @app_name)
    |> F.require_battery(state, :grafana)
  end
end
