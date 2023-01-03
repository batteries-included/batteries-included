defmodule Mix.Tasks.Gen.Dashboard do
  @shortdoc "Create json files to be embedded into kube resources with grafana dashobards"
  @moduledoc "The mix task to generate a dashboard json for grafana"

  use Mix.Task

  alias CommonCore.GrafanaDashboardClient

  @requirements ["app.config"]

  def run(args) do
    [app_name, dashboard_id] = args
    {:ok, dash} = GrafanaDashboardClient.dashboard(dashboard_id)

    dir = "apps/kube_resources/priv/raw_files/#{app_name}/"
    file_name = "dashboard_#{dashboard_id}.json"

    File.mkdir_p!(dir)

    contents = dash |> Map.get("json") |> Jason.encode!(pretty: true)

    File.write!(Path.join(dir, file_name), contents)
  end
end
