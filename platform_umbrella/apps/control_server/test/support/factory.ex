defmodule ControlServer.Factory do
  @moduledoc """

  Factory for control_server ecto.
  """

  # with Ecto
  use ExMachina.Ecto, repo: ControlServer.Repo

  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Postgres
  alias CommonCore.Redis.RedisInstance
  alias CommonCore.Resources.Hashing
  alias CommonCore.Timeline
  alias CommonCore.Timeline.TimelineEvent
  alias ControlServer.ContentAddressable.Document

  def umbrella_snapshot_factory do
    %ControlServer.SnapshotApply.UmbrellaSnapshot{}
  end

  def deleted_resource_factory do
    %ControlServer.Deleted.DeletedResource{
      name: sequence("deleted-resource-"),
      namespace: sequence("battery-core-"),
      kind: sequence(:kind, CommonCore.ApiVersionKind.all_known()),
      hash: Hashing.compute_hash(%{}),
      been_undeleted: false
    }
  end

  def kube_snapshot_factory do
    %ControlServer.SnapshotApply.KubeSnapshot{
      status: sequence(:status, [:creation, :generation, :applying, :ok, :error])
    }
  end

  def resource_path_factory do
    %ControlServer.SnapshotApply.ResourcePath{
      path: sequence("/path/path-"),
      # Junk hash this might break things
      hash: Hashing.compute_hash(%{}),
      name: sequence("resource-path-"),
      type: sequence(:type, CommonCore.ApiVersionKind.all_known()),
      is_success: sequence(:is_success, [true, false])
    }
  end

  def project_factory do
    %CommonCore.Projects.Project{
      name: sequence("project-"),
      type: sequence(:type, [:web, :ai, :db]),
      description: sequence("description-")
    }
  end

  def postgres_user_factory do
    %Postgres.PGUser{
      username: sequence("postgres-cluster-"),
      roles: ["login"]
    }
  end

  def postgres_cluster_factory(attrs \\ %{}) do
    # Ensure this is a map
    attrs = Map.new(attrs)

    user_one = build(:postgres_user)
    user_two = build(:postgres_user)

    name = Map.get_lazy(attrs, :name, fn -> sequence("postgres-cluster-") end)
    num_instances = Map.get_lazy(attrs, :num_instances, fn -> sequence(:num_instances, [1, 2, 5]) end)
    type = Map.get_lazy(attrs, :type, fn -> sequence(:type, ~w(standard internal)a) end)
    project_id = Map.get(attrs, :project_id, nil)

    virtual_size =
      Map.get_lazy(attrs, :virtual_size, fn -> sequence(:virtual_size, ~w(tiny small medium large xlarge huge)) end)

    # Factories don't go through changesets so we apply the virtual size attributes here
    # if there is one
    virtual_size_attrs =
      CommonCore.Postgres.Cluster.presets() |> Enum.find(%{}, fn pre -> pre.name == virtual_size end) |> Map.delete(:name)

    storage_class = Map.get(attrs, :storage_class, "default")

    %Postgres.Cluster{
      name: name,
      num_instances: num_instances,
      type: type,
      storage_class: storage_class,
      virtual_size: virtual_size,
      database: %{name: "postgres", owner: user_one.username},
      users: [user_one, user_two],
      project_id: project_id
    }
    |> merge_attributes(virtual_size_attrs)
    |> evaluate_lazy_attributes()
  end

  def redis_cluster_factory do
    %RedisInstance{
      name: sequence("redis-cluster-"),
      num_instances: sequence(:num_instances, [1, 2, 3, 4, 5, 9]),
      type: sequence(:redis_type, [:standard, :internal])
    }
  end

  def jupyter_lab_notebook_factory do
    %JupyterLabNotebook{
      name: sequence("kube-notebook-"),
      storage_size: 500 * 1024 * 1024,
      storage_class: "default"
    }
  end

  def containers_container_factory do
    %CommonCore.Containers.Container{name: sequence("knative-container-"), image: "nginx:latest"}
  end

  def containers_env_value_factory do
    %CommonCore.Containers.EnvValue{name: sequence("env-value-"), value: "test", source_type: :value}
  end

  def port_factory do
    %CommonCore.Port{
      name: sequence("port-"),
      number: sequence(:port, [80, 443, 8080, 22, 8000]),
      protocol: sequence(:protocol, [:tcp, :sctp, :udp])
    }
  end

  @spec knative_service_factory() :: CommonCore.Knative.Service.t()
  def knative_service_factory do
    %CommonCore.Knative.Service{
      name: sequence("knative-service-"),
      rollout_duration: sequence(:rollout_duration, ["10s", "1m", "2m", "10m", "20m", "30m"]),
      oauth2_proxy: sequence(:oauth2_proxy, [true, false]),
      keycloak_realm: sequence("realm_"),
      containers: [build(:containers_container)],
      env_values: [build(:containers_env_value), build(:containers_env_value)]
    }
  end

  @spec knative_service_factory() :: CommonCore.TraditionalServices.Service.t()
  def traditional_service_factory do
    %CommonCore.TraditionalServices.Service{
      name: sequence("knative-service-"),
      virtual_size: sequence(:virtual_size, ~w(tiny small medium large xlarge huge)),
      kube_deployment_type: sequence(:kube_deployment_type, [:statefulset, :deployment]),
      num_instances: sequence(:num_instances, [1, 2, 3, 4]),
      containers: [build(:containers_container)],
      env_values: [build(:containers_env_value), build(:containers_env_value)]
    }
  end

  @spec content_addressable_document_factory() :: Document.t()
  def content_addressable_document_factory do
    value = %{name: sequence("value-name-"), age: sequence(:age, [1, 2, 3, 4, 5])}
    hash = Hashing.compute_hash(value)

    %Document{
      hash: hash,
      id: Document.hash_to_uuid!(hash),
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
      entity_id: CommonCore.Ecto.BatteryUUID.autogenerate(),
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
