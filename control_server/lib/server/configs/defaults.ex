defmodule Server.Configs.Defaults do
  @moduledoc """
  Module for creating the default configs for a new KubeCluster
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Server.Configs.Adoption
  alias Server.Configs.Prometheus
  alias Server.Configs.RunningSet
  alias Server.Repo

  def create_all() do
    Multi.new()
    |> Multi.run(:running_set_config, fn _repo, _ ->
      RunningSet.create()
    end)
    |> Multi.run(:prometheus_config, fn _repo, _ ->
      Prometheus.create()
    end)
    |> Repo.transaction()
  end
end
