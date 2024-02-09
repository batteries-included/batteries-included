defmodule CommonCore.Factory do
  @moduledoc """

  Factory for creating db represenetions needed in kube_resources
  """

  # with Ecto
  use ExMachina

  def notebook_factory do
    %{
      name: sequence("test-notebook"),
      image: "jupyter/datascience-notebook:lab-3.2.9"
    }
  end

  def postgres_factory do
    %{
      name: sequence("test-postgres-cluster"),
      storage_size: 524_288_000
    }
  end

  def redis_factory do
    %{
      name: sequence("test-redis-failover"),
      num_redis_instances: sequence(:num_redis_instances, [3, 5, 7, 9]),
      num_sentinel_instances: sequence(:num_sentinel_instances, [1, 2, 3])
    }
  end

  def system_battery do
    %{
      config: %{},
      type:
        sequence(:type, [
          :battery_core,
          :control_server,
          :data,
          :postgres,
          :dev_metallb,
          :gitea,
          :istio,
          :istio_gateway,
          :kiali,
          :knative,
          :knative_serving,
          :metallb,
          :notebooks,
          :redis
        ])
    }
  end
end
