defmodule WhatsUp.DetectorFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `WhatsUp.Detector` context.
  """

  @doc """
  Generate a site.
  """
  def site_fixture(attrs \\ %{}) do
    {:ok, site} =
      attrs
      |> Enum.into(%{
        timeout: 4200,
        url: "https://google.com"
      })
      |> WhatsUp.Detector.create_site()

    site
  end
end
