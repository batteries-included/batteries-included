defmodule KubeRawResources.Battery do
  import KubeExt.Yaml

  alias KubeExt.Builder, as: B
  alias KubeRawResources.BatterySettings

  @bootstrapped_path "priv/manifests/battery/bootstrapped.yaml"
  @app_name "batteries-included"

  def crd(_), do: yaml(bootstrapped_content())
  defp bootstrapped_content, do: unquote(File.read!(@bootstrapped_path))

  @default_pg_cluster %{
    :name => "control",
    :postgres_version => "13",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => %{"controlserver" => ["superuser", "createrole", "createdb", "login"]},
    :databases => %{"control" => "controlserver"},
    :team_name => "pg"
  }

  def control_cluster do
    @default_pg_cluster
  end

  def namespace(config) do
    name = BatterySettings.namespace(config)

    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name(name)
  end

  def service_account(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name("battery-admin")
    |> B.app_labels(@app_name)
  end

  def cluster_role_binding(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-admin-cluster-admin")
    |> B.app_labels(@app_name)
    |> Map.put(
      "roleRef",
      B.build_cluster_role_ref("cluster-admin")
    )
    |> Map.put("subjects", [
      B.build_service_account("battery-admin", namespace)
    ])
  end

  def materialize(config) do
    %{
      "/crd" => crd(config),
      "/namespace" => namespace(config),
      "/service_account" => service_account(config),
      "/cluster_role_binding" => cluster_role_binding(config)
    }
  end
end
