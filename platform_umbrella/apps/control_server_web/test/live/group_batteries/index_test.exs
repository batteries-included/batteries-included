defmodule ControlServerWeb.GroupBatteries.IndexLiveTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  alias ControlServer.Batteries.Installer
  alias KubeServices.SystemState.Summarizer

  setup ctx do
    Installer.install!(:battery_core)
    Summarizer.new()
    ctx
  end

  describe "magic group batteries" do
    test "can list the group batteries", %{conn: conn} do
      conn
      |> start(~p"/batteries/magic")
      |> assert_html("Magic Batteries")
      |> assert_element(~s(a[href="/magic"]))
    end
  end

  describe "AI group batteries" do
    test "can list the group batteries", %{conn: conn} do
      conn
      |> start(~p"/batteries/ai")
      |> assert_html("AI Batteries")
      |> assert_element(~s(a[href="/ai"]))
    end
  end

  describe "Data group batteries" do
    test "can list the group batteries", %{conn: conn} do
      conn
      |> start(~p"/batteries/data")
      |> assert_html("Datastore Batteries")
      |> assert_element(~s(a[href="/data"]))
    end
  end

  describe "DevTools group batteries" do
    test "can list the group batteries", %{conn: conn} do
      conn
      |> start(~p"/batteries/devtools")
      |> assert_html("Devtool Batteries")
      |> assert_element(~s(a[href="/devtools"]))
    end
  end

  describe "Monitoring group batteries" do
    test "can list the group batteries", %{conn: conn} do
      conn
      |> start(~p"/batteries/monitoring")
      |> assert_html("Monitoring Batteries")
      |> assert_element(~s(a[href="/devtools"]))
    end
  end

  describe "Network Security group batteries" do
    test "can list the group batteries", %{conn: conn} do
      conn
      |> start(~p"/batteries/net_sec")
      |> assert_html("Net/Security Batteries")
      |> assert_element(~s(a[href="/net_sec"]))
    end
  end
end
