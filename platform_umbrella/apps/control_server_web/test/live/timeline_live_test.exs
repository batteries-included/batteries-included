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
    random = Enum.map(0..5, fn _ -> insert(:timeline_event) end)
    kube = insert(:timeline_event, type: :kube)
    postgres = insert(:timeline_event, type: :named_database, schema_type: :postgres_cluster)
    knative = insert(:timeline_event, type: :named_database, schema_type: :knative_service)
    %{timeline_events: random ++ [kube, postgres, knative]}
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
      |> assert_html("KNative Serverless")
    end
  end
end
