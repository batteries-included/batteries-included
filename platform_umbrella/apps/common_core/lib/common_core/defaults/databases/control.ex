defmodule CommonCore.Defaults.ControlDB do
  @moduledoc false

  @cluster_name "controlserver"
  @username "battery-control-user"
  @database_name "control"

  def local_user do
    %{username: "battery-local-user", roles: ["superuser", "createrole", "createdb", "login"], password: "not-real"}
  end

  def control_cluster(additional_namespaces \\ [], size \\ :tiny) do
    %{
      :name => @cluster_name,
      :num_instances => 1,
      :virtual_size => to_string(size),
      :type => :internal,
      :users => [
        %{username: @username, roles: ["createdb", "login"], credential_namespaces: additional_namespaces}
      ],
      :database => %{name: @database_name, owner: @username}
    }
  end

  def cluster_name, do: @cluster_name
  def user_name, do: @username
  def database_name, do: @database_name
end
