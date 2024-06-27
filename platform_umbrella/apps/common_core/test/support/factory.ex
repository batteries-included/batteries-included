defmodule CommonCore.Factory do
  @moduledoc """

  Factory for creating db represenetions needed in kube_resources
  """
  use ExMachina

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.StateSummary.KeycloakSummary

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

  def usage_report_factory(attrs \\ %{}) do
    # Ensure this is a map
    attrs = Map.new(attrs)

    batteries = Map.get_lazy(attrs, :batteries, fn -> ~w(battery_core postgres knative istio) end)
    node_report = Map.get_lazy(attrs, :node_report, fn -> node_report_factory() end)
    namespace_report = Map.get_lazy(attrs, :namespace_report, fn -> namespace_report_factory() end)
    postgres_report = Map.get_lazy(attrs, :postgres_report, fn -> postgres_report_factory() end)
    redis_report = Map.get_lazy(attrs, :redis_report, fn -> redis_report_factory() end)

    %CommonCore.ET.UsageReport{
      batteries: batteries,
      num_projects: 0,
      node_report: node_report,
      namespace_report: namespace_report,
      postgres_report: postgres_report,
      redis_report: redis_report
    }
  end

  def host_report_factory(attrs \\ %{}) do
    attrs = Map.new(attrs)

    control_server_host = Map.get(attrs, :control_server_host, "control.127-0-0-1.batrsinc.co")

    %CommonCore.ET.HostReport{control_server_host: control_server_host}
  end

  def node_report_factory do
    %CommonCore.ET.NodeReport{
      avg_cores: sequence(:avg_cores, [2.0, 8.0, 16.0, 32.0]),
      avg_mem: sequence(:avg_mem, [1_073_741_824.0, 2_147_483_648.0, 4_294_967_296.0, 8_589_934_592.0]),
      pod_counts: %{
        "node1" => 1,
        "node2" => 2,
        "node3" => 3,
        "node4" => 4
      }
    }
  end

  def namespace_report_factory do
    %CommonCore.ET.NamespaceReport{
      pod_counts: %{
        "battery-core" => 1,
        "default" => 2,
        "battery-knative" => 3,
        "battery-data" => 5
      }
    }
  end

  def postgres_report_factory do
    %CommonCore.ET.PostgresReport{
      instance_counts: %{"internal.controlserver" => 1}
    }
  end

  def redis_report_factory do
    %CommonCore.ET.RedisReport{
      instance_counts: %{"standard.test" => 1},
      sentinel_instance_counts: %{"standard.test" => 0}
    }
  end

  def install_spec_factory(attrs) do
    installation = build(:installation, attrs)

    # Drop properties that install uses
    clean_attrs = Map.drop(attrs, [:usage, :kube_provider, :kube_provider_config, :default_size])

    # merge attributes and evaluate lazy attributes at the end to emulate
    # ExMachina's default behavior
    installation
    |> CommonCore.InstallSpec.new!()
    |> put_in([Access.key!(:target_summary), Access.key!(:keycloak_state)], build(:keycloak_summary))
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

  def keycloak_summary_factory do
    %KeycloakSummary{realms: build_list(2, :realm)}
  end

  def realm_factory do
    %RealmRepresentation{
      attributes: build(:attributes),
      clients: build_list(2, :client)
    }
  end

  def attributes_factory do
    %{
      "cibaAuthRequestedUserHint" => "login_hint",
      "cibaBackchannelTokenDeliveryMode" => "poll",
      "cibaExpiresIn" => "120",
      "cibaInterval" => "5",
      "oauth2DeviceCodeLifespan" => "600",
      "oauth2DevicePollingInterval" => "5",
      "parRequestUriLifespan" => "60",
      "realmReusableOtpCode" => "false"
    }
  end

  def client_factory do
    %ClientRepresentation{id: BatteryUUID.autogenerate(), name: sequence("keycloak-client")}
  end
end
