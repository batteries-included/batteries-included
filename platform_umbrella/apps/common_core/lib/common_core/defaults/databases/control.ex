defmodule CommonCore.Defaults.ControlDB do
  @moduledoc false

  @cluster_name "controlserver"
  @username "battery-control-user"
  @database_name "control"

  def local_user do
    %{username: "battery-local-user", roles: ["superuser", "createrole", "createdb", "login"]}
  end

  def local_user_password_version do
    %{username: "battery-local-user", version: 1, password: "not-real"}
  end

  def control_cluster(additional_namespaces \\ [], size \\ :tiny) do
    %{
      :name => @cluster_name,
      :num_instances => 1,
      :virtual_size => to_string(size),
      :type => :internal,
      :users => [
        %{username: @username, roles: ["superuser", "createdb", "login"], credential_namespaces: additional_namespaces}
      ],
      :password_versions => [],
      :database => %{name: @database_name, owner: @username}
    }
  end

  def cluster_name, do: @cluster_name
  def user_name, do: @username
  def database_name, do: @database_name
end
