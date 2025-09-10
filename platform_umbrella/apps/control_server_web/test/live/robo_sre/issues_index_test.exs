defmodule ControlServerWeb.Live.RoboSRE.IssuesIndexTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  setup do
    # Create some test issues
    issue1 =
      insert(:issue, %{
        subject: "cluster-1.pod.test-app",
        subject_type: :pod,
        issue_type: :stuck_kubestate,
        status: :detected,
        trigger: :kubernetes_event,
        trigger_params: %{"event_type" => "Warning", "reason" => "Failed"}
      })

    issue2 =
      insert(:issue, %{
        subject: "cluster-1.control_server.main",
        subject_type: :control_server,
        issue_type: :stale_resource,
        status: :remediating,
        trigger: :metric_threshold,
        trigger_params: %{"metric" => "memory_usage", "threshold" => 90}
      })

    issue3 =
      insert(:issue, %{
        subject: "cluster-1.cluster_resource.config",
        subject_type: :cluster_resource,
        issue_type: :stuck_kubestate,
        status: :resolved,
        trigger: :health_check,
        trigger_params: %{}
      })

    %{issues: [issue1, issue2, issue3]}
  end

  describe "issues index page" do
    test "renders the issues list page", %{conn: conn} do
      conn
      |> start(~p"/robo_sre/issues")
      |> assert_html("RoboSRE Issues")
      |> assert_html("Total Issues")
      |> assert_html("Open Issues")
    end

    test "shows issues in the table", %{conn: conn, issues: [issue1, issue2, issue3]} do
      conn
      |> start(~p"/robo_sre/issues")
      |> assert_html(issue1.subject)
      |> assert_html(issue2.subject)
      |> assert_html(issue3.subject)
      |> assert_html("Detected")
      |> assert_html("Remediating")
      |> assert_html("Resolved")
    end

    test "allows filtering by subject", %{conn: conn} do
      conn
      |> start(~p"/robo_sre/issues")
      |> assert_html("Filter by subject...")
    end

    test "shows back link to magic page", %{conn: conn} do
      conn
      |> start(~p"/robo_sre/issues")
      |> assert_element("a[href='/magic']")
    end

    test "can click on issue to view details", %{conn: conn} do
      conn
      |> start(~p"/robo_sre/issues")
      |> click("tbody tr:first-child a", "View")
      |> follow()
      |> assert_html("Issue Details")
    end
  end

  describe "search and filtering" do
    test "can filter by subject", %{conn: conn} do
      conn
      |> start(~p"/robo_sre/issues")
      |> assert_element("input[name='subject']")
    end

    test "search form submission updates URL", %{conn: conn} do
      conn
      |> start(~p"/robo_sre/issues")
      |> form("form", %{
        "subject" => "detected"
      })
      # Should show filtered results
      |> assert_html("detected")
    end
  end
end
