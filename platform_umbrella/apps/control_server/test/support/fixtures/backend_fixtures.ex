defmodule ControlServer.BackendFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Backend` context.
  """

  @doc """
  Generate a service.
  """
  def service_fixture(attrs \\ %{}) do
    {:ok, service} =
      attrs
      |> Enum.into(%{
        containers: [],
        env_values: [],
        init_containers: [],
        name: "some-name"
      })
      |> ControlServer.Backend.create_service()

    service
  end
end
