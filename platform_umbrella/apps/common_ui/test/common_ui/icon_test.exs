defmodule CommonUI.IconTest do
  use Heyya.SnapshotTest

  import CommonUI.Icons.Batteries
  import CommonUI.Icons.Database
  import CommonUI.Icons.Devtools
  import CommonUI.Icons.Monitoring
  import CommonUI.Icons.Network
  import CommonUI.Icons.Notebook

  component_snapshot_test "Logo Icon" do
    assigns = %{}

    ~H"""
    <.batteries_logo />
    """
  end

  component_snapshot_test "Redis Icon" do
    assigns = %{}

    ~H"""
    <.redis_icon />
    """
  end

  component_snapshot_test "Devtools Icon" do
    assigns = %{}

    ~H"""
    <.devtools_icon />
    """
  end

  component_snapshot_test "Gitea Icon" do
    assigns = %{}

    ~H"""
    <.gitea_icon />
    """
  end

  component_snapshot_test "Grafana Icon" do
    assigns = %{}

    ~H"""
    <.grafana_icon />
    """
  end

  component_snapshot_test "Prometheus Icon" do
    assigns = %{}

    ~H"""
    <.prometheus_icon />
    """
  end

  component_snapshot_test "Alertmanager Icon" do
    assigns = %{}

    ~H"""
    <.alertmanager_icon />
    """
  end

  component_snapshot_test "Kiali Icon" do
    assigns = %{}

    ~H"""
    <.kiali_icon />
    """
  end

  component_snapshot_test "NetSec Icon" do
    assigns = %{}

    ~H"""
    <.net_sec_icon />
    """
  end

  component_snapshot_test "Notebook Icon" do
    assigns = %{}

    ~H"""
    <.notebook_icon />
    """
  end
end
