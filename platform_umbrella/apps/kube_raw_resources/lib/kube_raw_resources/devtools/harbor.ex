defmodule KubeRawResources.Harbor do
  @username "harbor"
  @cluster_name "harbor"
  @team "pg"
  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "13",
    :num_instances => 1,
    :storage_size => "200M",
    :type => :internal,
    :users => %{@username => ["superuser", "createrole", "createdb", "login"]},
    :databases => %{
      "registry" => @username,
      "harbor" => @username,
      "notary_signer" => @username
    },
    :team_name => @team
  }

  @default_redis_cluster %{
    :name => @cluster_name,
    :num_redis_instances => 1,
    :num_sentinel_instances => 1,
    :type => :internal
  }

  def harbor_pg_cluster do
    @default_pg_cluster
  end

  def harbor_redis_cluster do
    @default_redis_cluster
  end

  @spec db_username :: binary()
  def db_username, do: @username
  @spec db_name :: binary()
  def db_name, do: @cluster_name
  @spec db_team :: binary()
  def db_team, do: @team
end
