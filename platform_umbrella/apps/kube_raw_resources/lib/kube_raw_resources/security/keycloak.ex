defmodule KubeRawResources.Keycloak do
  @default_pg_cluster %{
    :name => "keycloak",
    :postgres_version => "13",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => %{"keycloakuser" => ["superuser", "createrole", "createdb", "login"]},
    :databases => %{"root" => "keycloakuser"},
    :team_name => "pg"
  }

  def keycloak_cluster do
    @default_pg_cluster
  end
end
