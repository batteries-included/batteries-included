defmodule ControlServerWeb.HealthzController do
  use ControlServerWeb, :controller

  action_fallback ControlServerWeb.FallbackController

  def index(conn, params) do
    status = check_healthz(conn, params)

    conn
    |> put_status(status[:status])
    |> json(status)
  end

  def check_healthz(conn, params) do
    with {:ok, _} <- check_kube_state_healthz(conn, params),
         {:ok, _} <- check_sql_repo_healthz(conn, params) do
      %{status: 200, message: "OK"}
    else
      {:error, message} ->
        %{status: 500, message: "Internal Server Error: #{message}"}
    end
  end

  defp check_kube_state_healthz(_conn, _params) do
    case KubeServices.KubeState.get_all(:pod) do
      # Assume for now that if there are pods
      # in the KubeState table, it is healthy
      [_ | _] ->
        {:ok, "KubeState is healthy"}

      [] ->
        {:error, "No pods in KubeState table"}
    end
  end

  defp check_sql_repo_healthz(_conn, _params) do
    Ecto.Adapters.SQL.query(ControlServer.Repo, "SELECT true", [])
  end
end
