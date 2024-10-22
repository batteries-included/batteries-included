defmodule CommonCore.Factory do
  @moduledoc """

  Factory for creating ecto represenetions needed in common_core
  """
  use ExMachina

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.Installs.Options
  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RealmRepresentation
  alias CommonCore.StateSummary.KeycloakSummary

  # with Ecto
  def state_summary_factory(attrs \\ %{}) do
    # Ensure this is a map
    attrs = Map.new(attrs)

    # use install spec factory to get the batteries and and a good starting place.
    install_spec = build(:install_spec, attrs)

    batteries = Map.get_lazy(attrs, :batteries, fn -> install_spec.target_summary.batteries end)
    captured_at = Map.get_lazy(attrs, :captured_at, fn -> DateTime.utc_now() end)
    stable_versions_report = Map.get_lazy(attrs, :stable_versions_report, fn -> build(:stable_versions_report, attrs) end)
    attrs = Map.take(attrs, [:batteries, :captured_at, :stable_versions_report])

    merge_attributes(
      %CommonCore.StateSummary{
        batteries: batteries,
        captured_at: captured_at,
        stable_versions_report: stable_versions_report
      },
      attrs
    )
  end

  def stable_versions_report_factory(attrs \\ %{}) do
    # Ensure this is a map
    attrs = Map.new(attrs)

    attrs = Map.take(attrs, [:control_server])

    merge_attributes(
      %CommonCore.ET.StableVersionsReport{
        control_server: Map.get(attrs, :control_server, "ghcr.io/batteries-included/control-server:v100.0.0")
      },
      attrs
    )
  end

  def installation_factory(attrs) do
    # Ensure this is a map
    attrs = Map.new(attrs)

    usage = Map.get_lazy(attrs, :usage, fn -> sequence(:usage, Keyword.values(Options.usages())) end)

    kube_provider =
      Map.get_lazy(attrs, :kube_provider, fn -> sequence(:kube_provider, Keyword.values(Options.providers())) end)

    kube_provider_config = Map.get_lazy(attrs, :kube_provider_config, fn -> %{} end)

    control_jwk = Map.get_lazy(attrs, :control_jwk, fn -> CommonCore.JWK.generate_key() end)

    user_id = Map.get(attrs, :user_id, nil)

    attrs = Map.take(attrs, ~w(slug kube_provider kube_provider_config default_size initial_oauth_email)a)

    %CommonCore.Installation{
      slug: sequence("test-installation"),
      kube_provider: kube_provider,
      kube_provider_config: kube_provider_config,
      usage: usage,
      control_jwk: control_jwk,
      user_id: user_id,
      default_size: sequence(:default_size, Options.sizes())
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
    knative_report = Map.get_lazy(attrs, :knative_report, fn -> knative_report_factory() end)

    traditional_services_report =
      Map.get_lazy(attrs, :traditional_services_report, fn -> traditional_services_report_factory() end)

    ollama_report = Map.get_lazy(attrs, :ollama_report, fn -> ollama_report_factory() end)

    %CommonCore.ET.UsageReport{
      batteries: batteries,
      num_projects: 0,
      node_report: node_report,
      namespace_report: namespace_report,
      postgres_report: postgres_report,
      redis_report: redis_report,
      knative_report: knative_report,
      traditional_services_report: traditional_services_report,
      ollama_report: ollama_report
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
    %CommonCore.ET.PostgresReport{instance_counts: %{"internal.controlserver" => 1}}
  end

  def redis_report_factory do
    %CommonCore.ET.RedisReport{instance_counts: %{"standard.test" => 1}}
  end

  def knative_report_factory do
    %CommonCore.ET.KnativeReport{
      pod_counts: %{
        "service-one" => 1,
        "another" => 0
      }
    }
  end

  def traditional_services_report_factory do
    %CommonCore.ET.TraditionalServicesReport{
      instance_counts: %{
        "service-one" => 1,
        "another" => 0
      }
    }
  end

  def ollama_report_factory do
    %CommonCore.ET.OllamaReport{
      instance_counts: %{"model-instance-one" => 1},
      model_counts: %{"llama3.1" => 1}
    }
  end

  def install_spec_factory(attrs) do
    installation = build(:installation, attrs)

    # Drop properties that install uses
    clean_attrs = Map.take(attrs, ~w(slug kube_cluster target_summary initial_resources)a)

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
      num_instances: sequence(:num_instances, [3, 5, 7, 9])
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
