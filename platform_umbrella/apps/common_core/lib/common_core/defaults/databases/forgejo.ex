defmodule CommonCore.Defaults.ForgejoDB do
  @moduledoc false
  @username "forgejo"
  @cluster_name "forgejo"
  @default_pg_cluster %{
    :name => @cluster_name,
    :num_instances => 1,
    :virtual_size => "tiny",
    :type => :internal,
    :users => [
      %{
        username: @username,
        roles: ["superuser", "createrole", "createdb", "login"],
        credential_namespaces: ["battery-core"]
      }
    ],
    :database => %{name: "forgejo", owner: @username}
  }

  def forgejo_cluster do
    @default_pg_cluster
  end

  def cluster_name, do: @cluster_name

  @spec db_username :: binary()
  def db_username, do: @username
  @spec db_name :: binary()
  def db_name, do: @cluster_name
end
