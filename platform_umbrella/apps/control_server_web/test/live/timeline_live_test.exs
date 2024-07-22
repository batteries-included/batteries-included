defmodule ControlServerWeb.Live.TimelineLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  describe "empty timeline page" do
    test "show", %{conn: conn} do
      conn
      |> start("/history/timeline")
      |> assert_html("Timeline")
    end
  end

  defp timeline_events(_) do
    %{timeline_events: Enum.map(0..25, fn _ -> insert(:timeline_event) end)}
  end

  describe "full timeline" do
    setup [:timeline_events]

    test "contains kube entity", %{conn: conn} do
      conn
      |> start("/history/timeline")
      |> assert_html("kube-resource-")
    end

    test "contains postgres", %{conn: conn} do
      conn
      |> start("/history/timeline")
      |> assert_html("Postgres Cluster")
    end

    test "contains knative", %{conn: conn} do
      conn
      |> start("/history/timeline")
      |> assert_html("Postgres Cluster")
    end
  end
end
