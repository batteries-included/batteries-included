defmodule KubeRawResources.Keycloak do
  @username "keycloakuser"
  @cluster_name "keycloak"
  @team "pg"
  @default_pg_cluster %{
    :name => "keycloak",
    :postgres_version => "13",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => %{@username => ["superuser", "createrole", "createdb", "login"]},
    :databases => %{"root" => @username},
    :team_name => @team
  }

  def keycloak_cluster do
    @default_pg_cluster
  end

  @spec db_username :: binary()
  def db_username, do: @username
  @spec db_name :: binary()
  def db_name, do: @cluster_name
  @spec db_team :: binary()
  def db_team, do: @team
end
