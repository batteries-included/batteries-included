defmodule CommonCore.Defaults.SSODB do
  @cluster_name "auth"
  @team "pg"

  @keycloak_username "keycloak"

  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "14",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => [
      %{username: @keycloak_username, roles: ["createdb", "login"]}
    ],
    :databases => [
      %{name: "keycloak", owner: @keycloak_username}
    ],
    :credential_copies => [
      %{username: @keycloak_username, namespace: "battery-core", format: :user_password}
    ],
    :team_name => @team
  }

  def pg_cluster do
    @default_pg_cluster
  end

  def db_name, do: @cluster_name
  @spec db_team :: binary()
  def db_team, do: @team
end
