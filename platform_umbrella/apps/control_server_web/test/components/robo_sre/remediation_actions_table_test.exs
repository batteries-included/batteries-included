defmodule ControlServerWeb.RoboSRE.RemediationActionsTableTest do
  use Heyya.SnapshotCase

  import ControlServerWeb.RoboSRE.RemediationActionsTable

  describe "remediation_actions_table/1" do
    component_snapshot_test "renders empty actions table" do
      assigns = %{actions: []}

      ~H"""
      <.remediation_actions_table actions={@actions} />
      """
    end

    component_snapshot_test "renders actions table with various action states" do
      actions = [
        %{
          action_type: :delete_resource,
          params: %{
            "name" => "test-resource",
            "namespace" => "default",
            "api_version_kind" => "apps/v1/Deployment"
          },
          executed_at: nil,
          result: nil
        },
        %{
          action_type: :restart_pod,
          params: %{
            "pod_name" => "test-pod-123",
            "namespace" => "production"
          },
          executed_at: ~U[2023-10-01 10:15:00Z],
          result: %{
            "success" => true,
            "message" => "Pod restarted successfully"
          }
        },
        %{
          action_type: :scale_deployment,
          params: %{
            "deployment" => "web-server",
            "replicas" => 3
          },
          executed_at: ~U[2023-10-01 10:20:00Z],
          result: %{
            "success" => false,
            "error" => "Insufficient resources to scale deployment"
          }
        },
        %{
          action_type: :cleanup_resource,
          params: %{},
          executed_at: ~U[2023-10-01 10:25:00Z],
          result: %{
            "message" => "Resource cleanup completed"
          }
        }
      ]

      assigns = %{actions: actions}

      ~H"""
      <.remediation_actions_table actions={@actions} />
      """
    end

    component_snapshot_test "renders actions with complex parameters" do
      actions = [
        %{
          action_type: :apply_yaml,
          params: %{
            "yaml_content" => %{
              "apiVersion" => "v1",
              "kind" => "ConfigMap",
              "metadata" => %{
                "name" => "app-config",
                "namespace" => "default"
              },
              "data" => %{
                "config.yml" => "setting: value"
              }
            },
            "timeout" => 300
          },
          executed_at: nil,
          result: nil
        }
      ]

      assigns = %{actions: actions}

      ~H"""
      <.remediation_actions_table actions={@actions} />
      """
    end

    component_snapshot_test "renders with custom id" do
      actions = [
        %{
          action_type: :test_action,
          params: %{"test" => "value"},
          executed_at: nil,
          result: nil
        }
      ]

      assigns = %{actions: actions}

      ~H"""
      <.remediation_actions_table actions={@actions} id="custom-actions-table" />
      """
    end
  end
end
