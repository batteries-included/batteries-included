defmodule ControlServerWeb.MagicHomeTest do
  use Heyya.LiveTest
  use ControlServerWeb.ConnCase

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  defp install_batteries(_) do
    timeline_report = Installer.install!(:timeline)
    stale_report = Installer.install!(:stale_resource_cleaner)
    %{timeline: timeline_report, stale: stale_report}
  end

  defp summary(_) do
    %{summary: Summarizer.new()}
  end

  describe "magic home with batteries" do
    setup [:install_batteries, :summary]

    test "contains links", %{conn: conn} do
      conn
      |> start("/magic")
      |> assert_html("Magic")
      |> assert_html("Deploys")
      |> assert_html("Timeline")
      |> assert_html("Delete Queue")
    end
  end

  describe "magic home page empty" do
    setup [:summary]

    test "contains bare bones", %{conn: conn} do
      # Test with nothing turned on, to test to make
      # sure it works whith things turned off
      conn
      |> start("/magic")
      |> assert_html("Magic")
      |> assert_html("Deploys")
      |> refute_html("Timeline")
      |> refute_html("Delete Queue")
    end
  end
end
