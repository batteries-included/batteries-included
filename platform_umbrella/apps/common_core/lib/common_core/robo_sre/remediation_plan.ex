defmodule CommonCore.RoboSRE.RemediationPlan do
  @moduledoc """
  A remediation plan for resolving RoboSRE issues.

  A plan consists of a sequence of actions that should be executed to resolve
  an infrastructure issue, along with configuration for timing, retries, and success criteria.
  """
  use CommonCore, :schema

  alias CommonCore.RoboSRE.Action

  batt_schema "robo_sre_remediation_plans" do
    belongs_to :issue, CommonCore.RoboSRE.Issue, type: CommonCore.Ecto.BatteryUUID
    has_many :actions, Action, preload_order: [asc: :order_index]
    field :retry_delay_ms, :integer, default: 59_000
    field :success_delay_ms, :integer, default: 30_000
    field :max_retries, :integer, default: 3
    field :current_action_index, :integer, default: 0

    timestamps()
  end

  def changeset(plan, params \\ %{}, opts \\ []) do
    plan
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> validate_number(:retry_delay_ms, greater_than: 0)
    |> validate_number(:success_delay_ms, greater_than: 0)
    |> validate_number(:max_retries, greater_than_or_equal_to: 0)
    |> validate_number(:current_action_index, greater_than_or_equal_to: 0)
  end

  def delete_resource(api_version_kind, namespace, name) do
    %__MODULE__{
      actions: [
        %Action{
          action_type: :delete_resource,
          params: %{
            name: name,
            namespace: namespace,
            api_version_kind: api_version_kind
          },
          order_index: 0
        }
      ]
    }
  end

  def restart_kube_state do
    %__MODULE__{
      actions: [
        %Action{
          action_type: :restart_kube_state,
          params: %{},
          order_index: 0
        }
      ]
    }
  end
end
