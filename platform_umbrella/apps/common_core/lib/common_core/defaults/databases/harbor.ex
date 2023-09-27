defmodule CommonCore.Defaults.HarborDB do
  @moduledoc false
  @username "harbor"
  @cluster_name "harbor"
  @team "pg"
  @default_pg_cluster %{
    :name => @cluster_name,
    :postgres_version => "14",
    :num_instances => 1,
    :storage_size => 209_715_200,
    :type => :internal,
    :users => [%{username: @username, roles: ["superuser", "createrole", "createdb", "login"]}],
    :databases => [
      %{name: "registry", owner: @username},
      %{name: "harbor", owner: @username},
      %{name: "notary_signer", owner: @username}
    ],
    :credential_copies => [
      %{username: @username, namespace: "battery-core", format: :user_password_host}
    ],
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
