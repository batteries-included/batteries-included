defmodule KubeRawResources.Gitea do
  @username "gitea"
  @cluster_name "gitea"
  @team "pg"
  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "13",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => %{@username => ["superuser", "createrole", "createdb", "login"]},
    :databases => %{"gitea" => @username},
    :team_name => @team
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
