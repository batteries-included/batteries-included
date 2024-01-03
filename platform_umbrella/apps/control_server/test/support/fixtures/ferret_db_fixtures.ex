defmodule ControlServer.FerretDBFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.FerretDB` context.
  """

  @doc """
  Generate a ferret_service.
  """
  def ferret_service_fixture(attrs \\ %{}) do
    {:ok, cluster} =
      ControlServer.Postgres.create_cluster(%{
        name: Ecto.UUID.generate(),
        num_instances: 1,
        virtual_size: "tiny",
        users: [%{username: "userone", roles: ["superuser"]}],
        database: %{name: "maindata", owner: "userone"}
      })

    {:ok, ferret_service} =
      attrs
      |> Enum.into(%{
        name: Ecto.UUID.generate(),
        virtual_size: nil,
        postgres_cluster_id: cluster.id,
        cpu_limits: 42,
        cpu_requested: 42,
        instances: 42,
        memory_limits: 42,
        memory_requested: 42
      })
      |> ControlServer.FerretDB.create_ferret_service()

    Map.put(ferret_service, :virtual_size, nil)
  end
end
