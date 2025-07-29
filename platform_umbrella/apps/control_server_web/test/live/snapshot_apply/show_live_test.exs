defmodule ControlServerWeb.Live.UmbrellaSnapshotShowTest do
  use ControlServerWeb.ConnCase

  import ControlServer.Factory
  import Phoenix.LiveViewTest

  setup do
    # Create a test umbrella snapshot with both kube and keycloak snapshots
    umbrella_snapshot =
      insert(:umbrella_snapshot, %{
        kube_snapshot: build(:kube_snapshot),
        keycloak_snapshot: build(:keycloak_snapshot)
      })

    %{umbrella_snapshot: umbrella_snapshot}
  end

  describe "mount" do
    test "loads the umbrella snapshot", %{conn: conn, umbrella_snapshot: snapshot} do
      {:ok, _view, html} = live(conn, ~p"/deploy/#{snapshot.id}/show")

      assert html =~ "Show Deploy"
      assert html =~ "Overview"
    end
  end

  describe "overview page" do
    test "shows overview with navigation tabs and deployment status", %{
      conn: conn,
      umbrella_snapshot: snapshot
    } do
      {:ok, _view, html} = live(conn, ~p"/deploy/#{snapshot.id}/show")

      assert html =~ "Deploy Status"
      assert html =~ "Overview"
      assert html =~ "Kubernetes"
      assert html =~ "Keycloak"
      assert html =~ "Status"
    end

    test "shows deployment status for kube and keycloak snapshots", %{
      conn: conn,
      umbrella_snapshot: snapshot
    } do
      {:ok, _view, html} = live(conn, ~p"/deploy/#{snapshot.id}/show")

      assert html =~ "Kubernetes Deployment"
      assert html =~ "Keycloak Deployment"
      # Should show status badges but no view details links
      refute html =~ "View Details"
    end
  end

  describe "kube page" do
    test "shows kubernetes deployment details", %{conn: conn, umbrella_snapshot: snapshot} do
      {:ok, _view, html} = live(conn, ~p"/deploy/#{snapshot.id}/kube")

      assert html =~ "Kubernetes Deploy"
      assert html =~ "Path Results"
    end

    test "shows message when no kube snapshot exists", %{conn: conn} do
      snapshot =
        insert(:umbrella_snapshot, %{
          kube_snapshot: nil,
          keycloak_snapshot: build(:keycloak_snapshot)
        })

      {:ok, view, _html} = live(conn, ~p"/deploy/#{snapshot.id}/show")

      # Should not show Kubernetes tab when no kube snapshot (check navigation panel specifically)
      refute has_element?(view, "a[href='/deploy/#{snapshot.id}/kube']")
    end
  end

  describe "keycloak page" do
    test "shows keycloak deployment details", %{conn: conn, umbrella_snapshot: snapshot} do
      {:ok, _view, html} = live(conn, ~p"/deploy/#{snapshot.id}/keycloak")

      assert html =~ "Keycloak Deploy"
      assert html =~ "Action Results"
    end

    test "shows message when no keycloak snapshot exists", %{conn: conn} do
      snapshot =
        insert(:umbrella_snapshot, %{
          kube_snapshot: build(:kube_snapshot),
          keycloak_snapshot: nil
        })

      {:ok, view, _html} = live(conn, ~p"/deploy/#{snapshot.id}/show")

      # Should not show Keycloak tab when no keycloak snapshot
      refute has_element?(view, "a[href='/deploy/#{snapshot.id}/keycloak']")
    end
  end

  describe "navigation" do
    test "can navigate between different views", %{conn: conn, umbrella_snapshot: snapshot} do
      {:ok, view, html} = live(conn, ~p"/deploy/#{snapshot.id}/show")

      # Start on overview
      assert html =~ "Deploy Status"

      # Navigate to kube page using the navigation tab (look for tab_bar context)
      view
      |> element("[data-phx-link='patch'][href='/deploy/#{snapshot.id}/kube']")
      |> render_click()

      assert_patch(view, ~p"/deploy/#{snapshot.id}/kube")

      # Navigate to keycloak page using the navigation tab
      view
      |> element("[data-phx-link='patch'][href='/deploy/#{snapshot.id}/keycloak']")
      |> render_click()

      assert_patch(view, ~p"/deploy/#{snapshot.id}/keycloak")

      # Navigate back to overview using the navigation tab
      view
      |> element("[data-phx-link='patch'][href='/deploy/#{snapshot.id}/show']")
      |> render_click()

      assert_patch(view, ~p"/deploy/#{snapshot.id}/show")
    end
  end
end
