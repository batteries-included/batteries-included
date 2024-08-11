defmodule CommonCore.Defaults.KeycloakDB do
  @moduledoc false
  @cluster_name "keycloak"

  @keycloak_username "keycloak"

  def pg_cluster(size \\ :tiny) do
    %{
      :name => @cluster_name,
      :num_instances => 1,
      :virtual_size => to_string(size),
      :type => :internal,
      :users => [
        %{username: @keycloak_username, roles: ["createdb", "login"], credential_namespaces: ["battery-core"]}
      ],
      :password_versions => [],
      :database => %{name: "keycloak", owner: @keycloak_username}
    }
  end

  def cluster_name, do: @cluster_name

  @spec db_username :: binary()
  def db_username, do: @keycloak_username

  def db_name, do: @cluster_name
end
