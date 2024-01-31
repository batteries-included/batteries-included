defmodule KubeBootstrap do
  @moduledoc """
  Documentation for `KubeBootstrap`.
  """

  require Logger

  def bootstrap_from_summary(summary) do
    conn = CommonCore.ConnectionPool.get(KubeBootstrap.ConnectionPool, :default)

    with {:ok, _} <- KubeBootstrap.Kube.ensure_exists(conn, summary),
         :ok <- KubeBootstrap.Postgres.wait_for_postgres(conn, summary) do
      Logger.info("Bootstrap complete")
    end
  end
end
