defmodule ControlServerWeb.SnapshotApply.ShowComponentsTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.SnapshotApply.ShowComponents

  describe "link_panel" do
    component_snapshot_test "shows all tabs when both snapshots exist" do
      snapshot = %{
        id: "test-id",
        kube_snapshot: %{id: "kube-id"},
        keycloak_snapshot: %{id: "keycloak-id"}
      }

      assigns = %{snapshot: snapshot, live_action: :overview}

      ~H"""
      <.link_panel live_action={@live_action} snapshot={@snapshot} />
      """
    end

    component_snapshot_test "shows only overview and kube tabs when no keycloak" do
      snapshot = %{
        id: "test-id",
        kube_snapshot: %{id: "kube-id"},
        keycloak_snapshot: nil
      }

      assigns = %{snapshot: snapshot, live_action: :kube}

      ~H"""
      <.link_panel live_action={@live_action} snapshot={@snapshot} />
      """
    end

    component_snapshot_test "shows only overview and keycloak tabs when no kube" do
      snapshot = %{
        id: "test-id",
        kube_snapshot: nil,
        keycloak_snapshot: %{id: "keycloak-id"}
      }

      assigns = %{snapshot: snapshot, live_action: :keycloak}

      ~H"""
      <.link_panel live_action={@live_action} snapshot={@snapshot} />
      """
    end
  end

  describe "no_actions component" do
    component_snapshot_test "displays no actions message" do
      assigns = %{}

      ~H"""
      <.no_actions />
      """
    end
  end
end
