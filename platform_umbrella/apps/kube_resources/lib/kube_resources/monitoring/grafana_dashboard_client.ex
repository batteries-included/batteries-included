defmodule KubeResources.GrafanaDashboardClient do
  alias Finch.Response

  @cache_name :grafana_dashboard_cache

  def child_spec do
    {Finch,
     name: __MODULE__,
     pools: %{
       "https://grafana.com/api/dashboards/" => [size: pool_size()]
     }}
  end

  defp pool_size do
    5
  end

  def dashboard(dashboard_id) do
    with {_, value} <-
           Cachex.fetch(@cache_name, dashboard_id, fn ->
             fetch_dashboard(dashboard_id)
           end) do
      value
    end
  end

  def fetch_dashboard(dashboard_id) do
    dashboard_id
    |> get_dashboard()
    |> handle_parent_response()
  end

  def get_dashboard(dashboard_id) do
    :get
    |> Finch.build("https://grafana.com/api/dashboards/#{dashboard_id}")
    |> Finch.request(__MODULE__)
  end

  def handle_parent_response({:ok, %Response{body: body, status: 200}}) do
    with {:ok, value} <- Jason.decode(body) do
      {:commit, Map.get(value, "json")}
    end
  end

  def handle_parent_response({:ok, %Response{status: 404}}), do: {:commit, %{}}
  def handle_parent_response(_), do: {:ignore, %{}}
end
