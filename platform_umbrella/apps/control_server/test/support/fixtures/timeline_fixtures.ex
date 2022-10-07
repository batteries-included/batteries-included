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
        level: :info,
        payload: %{__type__: :battery_install, type: :postgres_operator}
      })
      |> ControlServer.Timeline.create_timeline_event()

    timeline_event
  end
end
