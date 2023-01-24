defmodule CommonCore.Defaults.SsoDB do
  @kratos_username "orykratos"
  @hydra_username "oryhydra"

  @cluster_name "auth"
  @team "pg"

  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "14",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => [
      %{username: @kratos_username, roles: ["createdb", "login"]},
      %{username: @hydra_username, roles: ["createdb", "login"]}
    ],
    :databases => [
      %{name: "kratos", owner: @kratos_username},
      %{name: "hydra", owner: @hydra_username}
    ],
    :credential_copies => [
      %{username: @kratos_username, namespace: "battery-core", format: :user_password},
      %{username: @hydra_username, namespace: "battery-core", format: :user_password}
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
