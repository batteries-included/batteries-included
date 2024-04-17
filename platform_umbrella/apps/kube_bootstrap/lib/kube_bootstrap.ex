defmodule KubeBootstrap do
  @moduledoc """
  Documentation for `KubeBootstrap`.
  """
  alias CommonCore.StateSummary

  require Logger

  @spec bootstrap_from_summary(StateSummary.t()) :: :ok | {:error, :retries_exhausted | list()}
  def bootstrap_from_summary(summary) do
    conn = CommonCore.ConnectionPool.get(KubeBootstrap.ConnectionPool, :default)

    with {:ok, _} <- KubeBootstrap.Kube.ensure_exists(conn, summary),
         :ok <- KubeBootstrap.Postgres.wait_for_postgres(conn, summary) do
      Logger.info("Bootstrap complete")
      :ok
    end
  end

  @spec read_summary(binary()) :: {:ok, StateSummary.t()} | File.posix() | Jason.DecodeError.t()
  def read_summary(path) do
    with {:ok, file_contents} <- File.read(path),
         {:ok, decoded_content} <- Jason.decode(file_contents) do
      # Decode everything from string keyed map to struct
      StateSummary.new(decoded_content)
    else
      {:error, _} = error -> error
    end
  end
end
