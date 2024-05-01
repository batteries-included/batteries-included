defmodule CommonCore.Installs.Postgres do
  @moduledoc false
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Installation

  # Currently we only include the
  # Control Server db. That's to make onboarding as
  # simple as possible. Most configuraiton should
  # be done post install.
  def cluster_arg_list(batteries, installation) do
    batteries
    |> Enum.map(fn b -> cluster_args(b, installation) end)
    |> Enum.filter(&(&1 != nil))
  end

  defp cluster_args(%SystemBattery{type: :battery_core, config: config}, %Installation{
         usage: usage,
         default_size: default_size
       }) do
    cluster = CommonCore.Defaults.ControlDB.control_cluster([config.core_namespace], default_size)

    case usage do
      internal when internal in [:internal_dev, :internal_int_test] ->
        # For local development we add a user with a known password and roles
        users = [CommonCore.Defaults.ControlDB.local_user() | Map.get(cluster, :users, [])]
        %{cluster | users: users}

      _ ->
        cluster
    end
  end

  defp cluster_args(%SystemBattery{type: :forgejo}, %Installation{default_size: default_size}),
    do: CommonCore.Defaults.ForgejoDB.forgejo_cluster(default_size)

  defp cluster_args(%SystemBattery{type: :keycloak}, %Installation{default_size: default_size}),
    do: CommonCore.Defaults.KeycloakDB.pg_cluster(default_size)

  defp cluster_args(_, _), do: nil
end
