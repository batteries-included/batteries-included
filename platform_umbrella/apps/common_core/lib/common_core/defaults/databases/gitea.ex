defmodule CommonCore.Defaults.GiteaDB do
  @moduledoc false
  @username "gitea"
  @cluster_name "gitea"
  @team "pg"
  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "14",
    :num_instances => 1,
    :storage_size => 209_715_200,
    :type => :internal,
    :users => [%{username: @username, roles: ["superuser", "createrole", "createdb", "login"]}],
    :databases => [%{name: "gitea", owner: @username}],
    :team_name => @team,
    :credential_copies => [
      %{username: "gitea", namespace: "battery-core", format: :user_password_host}
    ]
  }

  def gitea_cluster do
    @default_pg_cluster
  end

  @spec db_username :: binary()
  def db_username, do: @username
  @spec db_name :: binary()
  def db_name, do: @cluster_name
  @spec db_team :: binary()
  def db_team, do: @team
end
