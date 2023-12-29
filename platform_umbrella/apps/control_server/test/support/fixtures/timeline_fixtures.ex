defmodule ControlServer.TimelineFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.Timeline` context.
  """

  @doc """
  Generate a timeline_event.
  """
  def timeline_event_fixture(attrs \\ %{}) do
    {:ok, timeline_event} =
      attrs
      |> Enum.into(%{
        type: :battery_install,
        payload: %{type: :battery_install, battery_type: :cloudnative_pg}
      })
      |> ControlServer.Timeline.create_timeline_event()

    timeline_event
  end
end
