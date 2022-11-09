defmodule KubeExt.RequiredDatabases.OryHydra do
  @username "hydra"
  @cluster_name "hydra"
  @team "pg"
  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "13",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => [%{username: @username, roles: ["superuser", "createrole", "createdb", "login"]}],
    :databases => [%{name: "root", owner: @username}, %{name: "hydra", owner: @username}],
    :team_name => @team
  }

  def hydra_cluster do
    @default_pg_cluster
  end

  @spec db_username :: binary()
  def db_username, do: @username
  @spec db_name :: binary()
  def db_name, do: @cluster_name
  @spec db_team :: binary()
  def db_team, do: @team
end
