defmodule KubeResources.ControlServerFactory do
  @moduledoc """

  Factory for creating db represenetions needed in kube_resources
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  def notebook_factory do
    %ControlServer.Notebooks.JupyterLabNotebook{
      name: sequence("test-notebook")
    }
  end

  def postgres_factory do
    %ControlServer.Postgres.Cluster{
      name: sequence("test-postgres-cluster"),
      storage_size: "1G"
    }
  end

  def redis_factory do
    %ControlServer.Redis.FailoverCluster{
      name: sequence("test-redis-failover"),
      num_redis_instances: sequence(:num_redis_instances, [3, 5, 7, 9]),
      num_sentinel_instances: sequence(:num_sentinel_instances, [1, 2, 3])
    }
  end
end
