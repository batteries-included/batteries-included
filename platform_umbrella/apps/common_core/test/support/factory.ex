defmodule CommonCore.Factory do
  @moduledoc """

  Factory for creating db represenetions needed in kube_resources
  """
  use ExMachina

  # with Ecto
  def installation_factory(attrs) do
    usage =
      Map.get_lazy(attrs, :usage, fn ->
        sequence(:usage, [:internal_dev, :internal_int_test, :development, :production, :kitchen_sink])
      end)

    %CommonCore.Installation{
      slug: sequence("test-installation"),
      kube_provider: sequence(:kube_provider, [:kind, :aws, :provided]),
      kube_provider_config: %{},
      usage: usage,
      initial_oauth_email: nil,
      default_size: sequence(:default_size, [:tiny, :small, :medium, :large, :xlarge, :huge])
    }
    |> merge_attributes(attrs)
    |> evaluate_lazy_attributes()
  end

  def install_spec_factory(attrs) do
    installation = build(:installation, attrs)

    # Drop properties that install uses
    clean_attrs = Map.drop(attrs, [:usage, :kube_provider, :kube_provider_config, :default_size])

    # merge attributes and evaluate lazy attributes at the end to emulate
    # ExMachina's default behavior
    installation
    |> CommonCore.InstallSpec.from_installation()
    |> merge_attributes(clean_attrs)
    |> evaluate_lazy_attributes()
  end

  def notebook_factory do
    %{
      name: sequence("test-notebook"),
      image: "jupyter/datascience-notebook:lab-3.2.9"
    }
  end

  def postgres_factory do
    %CommonCore.Postgres.Cluster{
      name: sequence("test-postgres-cluster"),
      storage_size: 524_288_000,
      cpu_requested: 500,
      cpu_limits: 500
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
          :forgejo,
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
