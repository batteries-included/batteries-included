defmodule CommonCore.Resources.VMDashboards do
  @moduledoc false
  use CommonCore.IncludeResource,
    dashboard_11176: "priv/raw_files/victoria_metrics/dashboard_11176.json",
    dashboard_12683: "priv/raw_files/victoria_metrics/dashboard_12683.json"

  use CommonCore.Resources.ResourceGenerator, app_name: "vm-dashboards"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:config_map_dashboard_11176, _battery, state) do
    namespace = core_namespace(state)
    data = %{"dashboard_11176.json" => get_resource(:dashboard_11176)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-dashboard-11176")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_dashboard", "1")
    |> B.label("grafana_folder", @app_name)
    |> F.require_battery(state, :grafana)
  end

  resource(:config_map_dashboard_12683, _battery, state) do
    namespace = core_namespace(state)
    data = %{"dashboard_14205.json" => get_resource(:dashboard_12683)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-dashboard-12682")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_dashboard", "1")
    |> B.label("grafana_folder", @app_name)
    |> F.require_battery(state, :grafana)
  end
end
