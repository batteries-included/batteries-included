defmodule ControlServerWeb.HealthzController do
  use ControlServerWeb, :controller

  require Logger

  @doc """
  Healthz controller for the control server.

  This will perform small actions to check the health of each of the subsystems

  - KubeState has some pods
  - SQL Repo can run a query
  - InstallStatusWorker is running
  - SnapshotApplyWorker has a last success (even if it is nil)
  """
  action_fallback ControlServerWeb.FallbackController

  def index(conn, params) do
    status = check_healthz(conn, params)

    Logger.debug("Healthz check: #{inspect(status)}", status: status)

    conn
    |> put_status(status[:status])
    |> json(status)
  end

  def check_healthz(conn, params) do
    with {:ok, _} <- check_kube_state_healthz(conn, params),
         {:ok, _} <- check_sql_repo_healthz(conn, params),
         {:ok, _} <- check_install_status_healthz(conn, params),
         {:ok, _} <- check_snapshot_apply_worker_healthz(conn, params) do
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

  defp check_install_status_healthz(_conn, _params) do
    case KubeServices.ET.InstallStatusWorker.get_status() do
      # Report healthy if the status returned.
      # This keeps the controlserver running even if the install status is not ok.
      # We want the control server to run and see if the status changes or clean up resources
      #
      # This check is simply here to make sure that the worker is running
      %CommonCore.ET.InstallStatus{} = status ->
        {:ok,
         "InstallStatusWorker is healthy. staus: #{status.status} iss: #{status.iss} exp: #{status.exp} message: #{status.message}"}

      _ ->
        {:error, "InstallStatusWorker is not healthy"}
    end
  end

  defp check_snapshot_apply_worker_healthz(_conn, _params) do
    case KubeServices.SnapshotApply.Worker.get_last_success() do
      {:ok, last} ->
        {:ok,
         "SnapshotApplyWorker is healthy. Previous Success: #{(last != nil && DateTime.to_iso8601(last)) || "never"}"}

      {:error, _} ->
        {:error, "SnapshotApplyWorker is not healthy"}
    end
  end
end
