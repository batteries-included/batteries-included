defmodule ControlServer.Factory do
  @moduledoc """

  Factory for control_server ecto.
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Postgres
  alias CommonCore.Redis.FailoverCluster
  alias CommonCore.Resources.Hashing
  alias CommonCore.Timeline
  alias CommonCore.Timeline.TimelineEvent

  def postgres_user_factory do
    %Postgres.PGUser{
      username: sequence("postgres_cluster-"),
      password: sequence("postgres_password-"),
      roles: ["login"]
    }
  end

  def postgres_cluster_factory do
    user_one = build(:postgres_user)
    user_two = build(:postgres_user)

    %Postgres.Cluster{
      name: sequence("postgres_cluster-"),
      num_instances: sequence(:num_instances, [1, 2, 5]),
      storage_size: 500 * 1024 * 1024,
      storage_class: "default",
      users: [user_one, user_two]
    }
  end

  def redis_cluster_factory do
    %FailoverCluster{
      name: sequence("redis-cluster-"),
      num_redis_instances: sequence(:num_redis_instances, [1, 2, 3, 4, 5, 9]),
      num_sentinel_instances: sequence(:num_sentinel_instances, [1, 2, 3, 4, 5, 9]),
      type: sequence(:redis_type, [:standard, :internal])
    }
  end

  def jupyter_lab_notebook_factory do
    %JupyterLabNotebook{name: sequence("kube-notebook-")}
  end

  def knative_container_factory do
    %CommonCore.Services.Container{name: sequence("knative-container-"), image: "nginx:latest"}
  end

  def knative_env_value_factory do
    %CommonCore.Services.EnvValue{name: sequence("env-value-"), value: "test", source_type: :value}
  end

  @spec knative_service_factory() :: CommonCore.Knative.Service.t()
  def knative_service_factory do
    %CommonCore.Knative.Service{
      name: sequence("knative-service-"),
      rollout_duration: sequence(:rollout_duration, ["10s", "1m", "2m", "10m", "20m", "30m"]),
      oauth2_proxy: sequence(:oauth2_proxy, [true, false]),
      containers: [build(:knative_container)],
      env_values: [build(:knative_env_value), build(:knative_env_value)]
    }
  end

  @spec content_addressable_document_factory() :: ControlServer.ContentAddressable.Document.t()
  def content_addressable_document_factory do
    value = %{name: sequence("value-name-"), age: sequence(:age, [1, 2, 3, 4, 5])}
    hash = Hashing.compute_hash(value)

    %ControlServer.ContentAddressable.Document{
      hash: hash,
      id: ControlServer.ContentAddressable.Document.hash_to_uuid!(hash),
      value: value
    }
  end

  def timeline_event_factory(attrs) do
    event_type = Map.get_lazy(attrs, :type, fn -> sequence(:event_type, [:battery_install, :kube, :named_database]) end)

    case event_type do
      :battery_install ->
        %TimelineEvent{payload: build(:battery_install_payload, attrs), type: event_type}

      :kube ->
        %TimelineEvent{payload: build(:kube_payload, attrs), type: event_type}

      :named_database ->
        %TimelineEvent{payload: build(:named_database_payload, attrs), type: event_type}

      _ ->
        raise "Unknown event type: #{inspect(event_type)}"
    end
  end

  def named_database_payload_factory do
    %Timeline.NamedDatabase{
      name: sequence("named-database-"),
      action: sequence(:action, [:insert, :update]),
      entity_id: sequence("named-entity-id-"),
      schema_type: sequence(:schema_type, Timeline.NamedDatabase.possible_schema_types())
    }
  end

  def kube_payload_factory do
    %Timeline.Kube{
      action: sequence(:action, [:add, :delete, :update]),
      resource_type: sequence(:resource_type, CommonCore.ApiVersionKind.all_known()),
      name: sequence("kube-resource-"),
      namespace: sequence(:namespace, ["default", "battery-core", "battery-data"]),
      computed_status:
        sequence(:computed_status, [:ready, :containers_ready, :initialized, :pod_has_network, :pod_scheduled, :unknown])
    }
  end

  def battery_install_payload_factory do
    %Timeline.BatteryInstall{
      battery_type: sequence(:battery_type, SystemBattery.possible_types())
    }
  end
end
