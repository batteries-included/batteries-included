defmodule ControlServerWeb.DataHomeTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  defp install_batteries(_) do
    pg_report = Installer.install!(:cloudnative_pg)
    redis_report = Installer.install!(:redis)
    %{pg: pg_report, redis: redis_report}
  end

  defp redis_instance(_) do
    %{redis_cluster: insert(:redis_instance)}
  end

  defp postgres_cluster(_) do
    %{postgres_cluster: insert(:postgres_cluster)}
  end

  defp summary(_) do
    %{summary: Summarizer.new()}
  end

  describe "data home page with everything" do
    setup [:install_batteries, :redis_instance, :postgres_cluster, :summary]

    test "show", %{conn: conn, postgres_cluster: postgres_cluster, redis_cluster: redis_cluster} do
      # Test while everything is turned on
      # This is to make sure that all the rendering works when filled out
      conn
      |> start("/data")
      |> assert_html("Datastores")
      |> assert_html(postgres_cluster.name)
      |> assert_html(redis_cluster.name)
    end
  end

  describe "data home page empty" do
    setup [:summary]

    test "show", %{conn: conn} do
      # Test with nothing turned on, to test to make
      # sure it works whith things turned off
      conn
      |> start("/data")
      |> assert_html("Datastores")
      |> refute_html("Redis")
      |> refute_html("Postgres")
    end

    test "contains empty home component", %{conn: conn} do
      conn
      |> start("/data")
      |> assert_html("Datastores")
      |> assert_html("There are no batteries installed for this group.")
    end
  end
end
