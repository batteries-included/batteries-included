defmodule KubeBootstrap do
  @moduledoc """
  Documentation for `KubeBootstrap`.
  """

  require Logger

  @spec bootstrap_from_summary(CommonCore.StateSummary.t()) ::
          :ok | {:error, :retries_exhausted | list()}
  def bootstrap_from_summary(summary) do
    conn = CommonCore.ConnectionPool.get(KubeBootstrap.ConnectionPool, :default)

    with {:ok, _} <- KubeBootstrap.Kube.ensure_exists(conn, summary),
         :ok <- KubeBootstrap.Postgres.wait_for_postgres(conn, summary) do
      Logger.info("Bootstrap complete")
      :ok
    end
  end
end
