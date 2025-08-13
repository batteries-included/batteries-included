defmodule CommonCore.GrafanaDashboardClient do
  @moduledoc false

  def client do
    Tesla.client(middleware(), adapter())
  end

  defp middleware do
    [Tesla.Middleware.JSON]
  end

  defp adapter do
    Finch
  end

  def dashboard(id) do
    url = "https://grafana.com/api/dashboards/#{id}"

    case Tesla.get(client(), url) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      {:error, exception} -> {:error, exception}
      err -> {:error, {:unknown_error, err}}
    end
  end
end
