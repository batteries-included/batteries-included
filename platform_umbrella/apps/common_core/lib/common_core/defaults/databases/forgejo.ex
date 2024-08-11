defmodule CommonCore.Defaults.ForgejoDB do
  @moduledoc false
  @username "forgejo"
  @cluster_name "forgejo"

  def forgejo_cluster(size \\ :tiny) do
    %{
      :name => @cluster_name,
      :num_instances => 1,
      :virtual_size => to_string(size),
      :type => :internal,
      :users => [
        %{
          username: @username,
          roles: ["superuser", "createrole", "createdb", "login"],
          credential_namespaces: ["battery-core"]
        }
      ],
      :password_versions => [],
      :database => %{name: "forgejo", owner: @username}
    }
  end

  def cluster_name, do: @cluster_name

  @spec db_username :: binary()
  def db_username, do: @username
  @spec db_name :: binary()
  def db_name, do: @cluster_name
end
