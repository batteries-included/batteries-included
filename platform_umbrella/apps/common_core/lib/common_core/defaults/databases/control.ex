defmodule CommonCore.Defaults.ControlDB do
  @moduledoc false
  @default_pg_cluster %{
    :name => "control",
    :postgres_version => "14",
    :num_instances => 1,
    :storage_size => 524_288_000,
    :type => :internal,
    :users => [
      %{username: "controlserver", roles: ["createdb", "login"]}
    ],
    :databases => [%{name: "control", owner: "controlserver"}],
    :team_name => "pg"
  }

  def control_cluster do
    @default_pg_cluster
  end
end
