defmodule ControlServerWeb.Live.RoboSRE.IssuesShowTest do
  use Heyya.LiveCase
  use ControlServerWeb.ConnCase

  import ControlServer.Factory

  setup do
    # Create a test issue
    issue =
      insert(:issue, %{
        subject: "cluster-1.pod.test-app",
        issue_type: :stuck_kubestate,
        status: :detected,
        trigger: :kubernetes_event,
        trigger_params: %{
          "event_type" => "Warning",
          "reason" => "Failed",
          "message" => "Pod failed to start"
        },
        handler: :stale_resource
      })

    # Create remediation plans
    plan1 =
      insert(:remediation_plan, %{
        issue_id: issue.id,
        retry_delay_ms: 60_000,
        success_delay_ms: 30_000,
        max_retries: 3,
        current_action_index: 0
      })

    action1 =
      insert(:action, %{
        remediation_plan_id: plan1.id,
        action_type: :delete_resource,
        params: %{
          "name" => "test-pod",
          "namespace" => "default",
          "api_version_kind" => "v1/Pod"
        },
        order_index: 0,
        executed_at: nil,
        result: nil
      })

    action2 =
      insert(:action, %{
        remediation_plan_id: plan1.id,
        action_type: :delete_resource,
        params: %{
          "pod_name" => "test-pod",
          "namespace" => "default"
        },
        order_index: 1,
        executed_at: ~U[2023-10-01 10:15:00Z],
        result: %{
          "success" => true,
          "message" => "Pod restarted successfully"
        }
      })

    %{issue: issue, plan: plan1, actions: [action1, action2]}
  end

  describe "issue show page" do
    test "renders the issue details page", %{conn: conn, issue: issue} do
      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_html("Issue Details")
      |> assert_html(issue.subject)
      |> assert_html("Detected")
    end

    test "shows issue details panel", %{conn: conn, issue: issue} do
      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_html("Subject")
      |> assert_html(issue.subject)
      |> assert_html("Pod")
      |> assert_html("Issue Type")
      |> assert_html("Stuck KubeState")
      |> assert_html("Trigger")
      |> assert_html("Kubernetes Event")
      |> assert_html("Handler")
      |> assert_html("Stale Resource")
    end

    test "shows trigger parameters panel", %{conn: conn, issue: issue} do
      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_html("Trigger Parameters")
      |> assert_html("event_type")
      |> assert_html("Warning")
      |> assert_html("reason")
      |> assert_html("Failed")
      |> assert_html("message")
      |> assert_html("Pod failed to start")
    end

    test "shows remediation plan when present", %{conn: conn, issue: issue} do
      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_html("Remediation Plan")
      |> assert_html("Max Retries")
      |> assert_html("Retry Delay")
      |> assert_html("Success Delay")
      |> assert_html("Current Action")
      |> assert_html("Actions (2)")
    end

    test "shows actions table in remediation plan", %{conn: conn, issue: issue} do
      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_html("Delete Resource")
      |> assert_html("Pending")
      |> assert_html("Success")
      |> assert_html("Pod restarted successfully")
    end

    test "shows back link to issues list", %{conn: conn, issue: issue} do
      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_element("a[href='/robo_sre/issues']")
    end

    test "handles issue with no trigger parameters", %{conn: conn} do
      issue =
        insert(:issue, %{
          subject: "cluster-1.pod.simple-app",
          trigger_params: %{}
        })

      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_html("No trigger parameters available")
    end

    test "handles issue with no remediation plans", %{conn: conn} do
      issue =
        insert(:issue, %{
          subject: "cluster-1.pod.another-app"
        })

      conn
      |> start(~p"/robo_sre/issues/#{issue.id}")
      |> assert_html("No remediation plans available")
    end
  end

  describe "multiple remediation plans" do
    test "shows tabs when multiple plans exist", %{conn: conn, issue: issue} do
      # Create a second plan
      plan2 =
        insert(:remediation_plan, %{
          issue_id: issue.id,
          retry_delay_ms: 120_000,
          max_retries: 1
        })

      insert(:action, %{
        remediation_plan_id: plan2.id,
        action_type: :delete_resource,
        params: %{"replicas" => 2},
        order_index: 0
      })

      view = start(conn, ~p"/robo_sre/issues/#{issue.id}")

      # Should show tabs for multiple plans
      view
      |> assert_html("Plan 1")
      |> assert_html("Plan 2")

      # Click on Plan 2 tab
      view
      |> click("a[phx-value-index='1']")
      |> assert_html("Delete Resource")
    end
  end
end
