defmodule CommonCore.Defaults.KeycloakDB do
  @moduledoc false
  @cluster_name "keycloak"

  @keycloak_username "keycloak"

  @default_pg_cluster %{
    :name => @cluster_name,
    :num_instances => 1,
    :storage_size => 209_715_200,
    :type => :internal,
    :users => [
      %{username: @keycloak_username, roles: ["createdb", "login"]}
    ],
    :databases => [
      %{name: "keycloak", owner: @keycloak_username}
    ],
    :credential_copies => [
      %{username: @keycloak_username, namespace: "battery-core", format: :user_password}
    ]
  }

  def pg_cluster do
    @default_pg_cluster
  end

  def cluster_name, do: @cluster_name

  @spec db_username :: binary()
  def db_username, do: @keycloak_username

  def db_name, do: @cluster_name
end
