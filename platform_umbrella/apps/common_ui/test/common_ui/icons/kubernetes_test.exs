defmodule CommonUI.Icons.KubernetesTest do
  use Heyya.SnapshotCase

  import CommonUI.Icons.Kubernetes

  component_snapshot_test "Kubernetes Icon" do
    assigns = %{}

    ~H"""
    <.icon />
    """
  end
end
