defmodule CommonCore.Defaults.OryDB do
  @kratos_username "orykratos"

  @cluster_name "ory"
  @team "pg"

  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "14",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => [
      %{username: @kratos_username, roles: ["createdb", "login"]}
    ],
    :databases => [
      %{name: "kratos", owner: @kratos_username}
    ],
    :credential_copies => [
      %{username: @kratos_username, namespace: "battery-core", format: :user_password}
    ],
    :team_name => @team
  }

  def ory_pg_cluster do
    @default_pg_cluster
  end

  def db_name, do: @cluster_name
  @spec db_team :: binary()
  def db_team, do: @team
end
