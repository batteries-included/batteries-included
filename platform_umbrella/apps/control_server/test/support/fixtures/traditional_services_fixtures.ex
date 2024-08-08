defmodule ControlServer.TraditionalServicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.TraditionalServices` context.
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
        virtural_size: "medium"
      })
      |> ControlServer.TraditionalServices.create_service()

    service
  end
end
