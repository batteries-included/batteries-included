defmodule CommonCore.RoboSRE.Action do
  @moduledoc """
  A single action within a remediation plan.
  """
  use CommonCore, :schema

  alias CommonCore.RoboSRE.ActionType

  batt_schema "robo_sre_actions" do
    belongs_to :remediation_plan, CommonCore.RoboSRE.RemediationPlan, type: CommonCore.Ecto.BatteryUUID
    field :action_type, ActionType
    field :params, :map, default: %{}
    field :result, :map
    field :executed_at, :utc_datetime_usec
    field :order_index, :integer

    timestamps()
  end

  def changeset(action, params \\ %{}, opts \\ []) do
    action
    |> CommonCore.Ecto.Schema.schema_changeset(params, opts)
    |> validate_required([:action_type, :order_index])
    |> validate_number(:order_index, greater_than_or_equal_to: 0)
  end
end
