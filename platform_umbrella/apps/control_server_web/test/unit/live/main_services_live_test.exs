defmodule ControlServerWeb.MainServiceLiveTest do
  @moduledoc """
  This test is to make sure that the most reachable service home pages are loadable
  """
  use ControlServerWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Data" do
    test "data home", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.data_home_path(conn, :index))

      assert html =~ "Home"
    end

    test "data system settings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.service_settings_path(conn, :data))
      assert html =~ "Postgres"
    end
  end

  describe "ML" do
    test "ML Notebooks system settings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.service_settings_path(conn, :ml))
      assert html =~ "Notebooks"
      assert html =~ "Machine Learning"
    end
  end

  describe "Monitoring" do
    test "Monitoring system settings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.service_settings_path(conn, :monitoring))

      assert html =~ "Monitoring"
      assert html =~ "grafana"
      assert html =~ "prometheus"
    end
  end

  describe "Security" do
    test "Security system settings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.service_settings_path(conn, :security))

      assert html =~ "keycloak"
    end
  end

  describe "Network" do
    test "Network system settings", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, Routes.service_settings_path(conn, :network))

      assert html =~ "istiod"
      assert html =~ "gateway"
    end
  end
end
