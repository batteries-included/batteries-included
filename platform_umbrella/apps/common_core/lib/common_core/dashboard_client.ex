defmodule CommonCore.GrafanaDashboardClient do
  use Tesla

  require Logger

  plug(Tesla.Middleware.JSON)

  def dashboard(id) do
    url = "https://grafana.com/api/dashboards/#{id}"

    case get(url) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:error, exception} -> {:error, exception}
      err -> {:error, {:unknown_error, err}}
    end
  end
end
