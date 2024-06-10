defmodule CommonCore.Resources.CloudnativePGDashboards do
  @moduledoc false
  use CommonCore.Resources.ResourceGenerator, app_name: "cloudnative-pg-dashboards"
  use CommonCore.IncludeResource, dashboard: "priv/raw_files/cloudnative_pg/grafana-dashboard.json"

  import CommonCore.StateSummary.Namespaces

  alias CommonCore.Resources.Builder, as: B
  alias CommonCore.Resources.FilterResource, as: F

  resource(:config_map_dashboard, _battery, state) do
    namespace = core_namespace(state)
    data = %{"cnp.json" => get_resource(:dashboard)}

    :config_map
    |> B.build_resource()
    |> B.name("grafana-dashboard-pg-cloudnative")
    |> B.namespace(namespace)
    |> B.data(data)
    |> B.label("grafana_dashboard", "1")
    |> B.label("grafana_folder", @app_name)
    |> B.annotation("grafana_folder", @app_name)
    |> F.require_battery(state, :grafana)
  end
end
