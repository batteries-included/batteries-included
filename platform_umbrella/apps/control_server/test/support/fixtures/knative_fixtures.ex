defmodule ControlServer.KnativeFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Knative` context.
  """

  @doc """
  Generate a service.
  """
  def service_fixture(attrs \\ %{}) do
    {:ok, service} =
      attrs
      |> Enum.into(%{
        name: "some name"
      })
      |> ControlServer.Knative.create_service()

    service
  end
end
