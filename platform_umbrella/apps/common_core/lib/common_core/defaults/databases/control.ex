defmodule CommonCore.Defaults.ControlDB do
  @moduledoc false

  @cluster_name "controlserver"
  @username "battery-control-user"
  @database_name "control"

  @default_pg_cluster %{
    :name => @cluster_name,
    :num_instances => 1,
    :storage_size => 524_288_000,
    :type => :internal,
    :users => [
      %{username: @username, roles: ["createdb", "login"]}
    ],
    :databases => [%{name: @database_name, owner: @username}]
  }

  def local_user do
    %{username: "battery-local-user", roles: ["superuser", "createrole", "createdb", "login"], password: "not-real"}
  end

  def control_cluster do
    @default_pg_cluster
  end

  def cluster_name, do: @cluster_name
  def user_name, do: @username
  def database_name, do: @database_name
end
