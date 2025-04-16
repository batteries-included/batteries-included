defmodule CommonCore.Installs.Postgres do
  @moduledoc false
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Defaults.ControlDB
  alias CommonCore.Installation
  alias CommonCore.Installs.TraditionalServices
  alias CommonCore.Postgres.PGBackupConfig

  # Currently we only include the
  # Control Server db. That's to make onboarding as
  # simple as possible. Most configuration should
  # be done post install.
  def cluster_arg_list(batteries, installation) do
    batteries
    |> Enum.flat_map(fn b -> cluster_args(b, installation) end)
    |> Enum.filter(&(&1 != nil))
  end

  defp cluster_args(%SystemBattery{type: :battery_core, config: config}, %Installation{
         usage: usage,
         default_size: default_size
       }) do
    cluster = ControlDB.control_cluster([config.core_namespace], default_size)

    case usage do
      internal when internal in [:internal_dev, :internal_int_test] ->
        # For local development we add a user with a known password and roles
        local_user = ControlDB.local_user()
        users = [local_user | Map.get(cluster, :users, [])]

        local_user_password_version = ControlDB.local_user_password_version()
        password_versions = [local_user_password_version | Map.get(config, :password_versions, [])]

        [%{cluster | users: users, password_versions: password_versions}]

      :internal_prod ->
        [Map.put_new(cluster, :backup_config, %PGBackupConfig{type: :object_store})]

      _ ->
        [cluster]
    end
  end

  defp cluster_args(%SystemBattery{type: :forgejo}, %Installation{default_size: default_size}),
    do: [CommonCore.Defaults.ForgejoDB.forgejo_cluster(default_size)]

  defp cluster_args(%SystemBattery{type: :keycloak}, %Installation{default_size: default_size}),
    do: [CommonCore.Defaults.KeycloakDB.pg_cluster(default_size)]

  defp cluster_args(%SystemBattery{type: :traditional_services, config: config}, %Installation{
         usage: usage,
         default_size: default_size
       }) do
    case usage do
      # create home-base and CLA assistant clusters
      usage when usage in [:internal_prod] ->
        home_base = TraditionalServices.home_base_name()
        cla = TraditionalServices.cla_name()

        Enum.map([home_base, cla], fn name ->
          %{
            :name => name,
            :num_instances => 1,
            :virtual_size => to_string(default_size),
            :type => :standard,
            :users => [
              %{username: name, roles: ["superuser", "createdb", "login"], credential_namespaces: [config.namespace]}
            ],
            :password_versions => [],
            :database => %{name: name, owner: name},
            :backup_config => %PGBackupConfig{type: :object_store}
          }
        end)

      _ ->
        []
    end
  end

  defp cluster_args(_, _), do: []
end
