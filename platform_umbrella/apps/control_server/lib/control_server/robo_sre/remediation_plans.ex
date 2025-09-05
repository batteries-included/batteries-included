defmodule ControlServer.RoboSRE.RemediationPlans do
  @moduledoc """
  Context for managing remediation plans and their actions.
  """

  use ControlServer, :context

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.RoboSRE.Action
  alias CommonCore.RoboSRE.RemediationPlan
  alias EventCenter.Database, as: DatabaseEventCenter

  @spec list_remediation_plans() :: list(RemediationPlan.t())
  def list_remediation_plans do
    Repo.all(RemediationPlan)
  end

  @spec list_remediation_plans(map()) :: {:ok, {[RemediationPlan.t()], Flop.Meta.t()}} | {:error, Flop.Meta.t()}
  def list_remediation_plans(params) do
    Repo.Flop.validate_and_run(RemediationPlan, params, for: RemediationPlan)
  end

  @spec get_remediation_plan!(BatteryUUID.t(), keyword()) :: RemediationPlan.t()
  def get_remediation_plan!(id, opts \\ []) do
    RemediationPlan
    |> preload(^Keyword.get(opts, :preload, [:actions]))
    |> Repo.get!(id)
  end

  @spec get_remediation_plan(BatteryUUID.t(), keyword()) :: RemediationPlan.t() | nil
  def get_remediation_plan(id, opts \\ []) do
    RemediationPlan
    |> preload(^Keyword.get(opts, :preload, [:actions]))
    |> Repo.get(id)
  end

  @spec create_remediation_plan(map()) :: {:ok, RemediationPlan.t()} | {:error, Ecto.Changeset.t()}
  def create_remediation_plan(attrs \\ %{}) do
    %RemediationPlan{}
    |> RemediationPlan.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:insert)
  end

  @spec update_remediation_plan(RemediationPlan.t(), map()) :: {:ok, RemediationPlan.t()} | {:error, Ecto.Changeset.t()}
  def update_remediation_plan(%RemediationPlan{} = plan, attrs) do
    plan
    |> RemediationPlan.changeset(attrs)
    |> Repo.update()
    |> broadcast(:update)
  end

  @spec delete_remediation_plan(RemediationPlan.t()) :: {:ok, RemediationPlan.t()} | {:error, Ecto.Changeset.t()}
  def delete_remediation_plan(%RemediationPlan{} = plan) do
    plan
    |> Repo.delete()
    |> broadcast(:delete)
  end

  @spec change_remediation_plan(RemediationPlan.t(), map()) :: Ecto.Changeset.t()
  def change_remediation_plan(%RemediationPlan{} = plan, attrs \\ %{}) do
    RemediationPlan.changeset(plan, attrs)
  end

  @spec find_remediation_plans_by_issue(BatteryUUID.t()) :: [RemediationPlan.t()]
  def find_remediation_plans_by_issue(issue_id) do
    Repo.all(
      from(p in RemediationPlan,
        where: p.issue_id == ^issue_id,
        order_by: [desc: :inserted_at],
        preload: [:actions]
      )
    )
  end

  @spec update_action_result(BatteryUUID.t(), map()) :: {:ok, Action.t()} | {:error, Ecto.Changeset.t()}
  def update_action_result(action_id, result) do
    action = Repo.get!(Action, action_id)

    action
    |> Action.changeset(%{result: result, executed_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @spec create_plan_with_actions(map(), list(map())) :: {:ok, RemediationPlan.t()} | {:error, Ecto.Changeset.t()}
  def create_plan_with_actions(plan_attrs, actions_attrs) do
    Repo.transaction(fn ->
      with {:ok, plan} <- create_remediation_plan(plan_attrs),
           {:ok, _actions} <- create_actions_for_plan(plan, actions_attrs) do
        get_remediation_plan!(plan.id, preload: [:actions])
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp create_actions_for_plan(plan, actions_attrs) do
    actions_with_plan_id =
      actions_attrs
      |> Enum.with_index()
      |> Enum.map(fn {action_attrs, index} ->
        action_attrs
        |> Map.put(:remediation_plan_id, plan.id)
        |> Map.put(:order_index, index)
      end)

    changesets = Enum.map(actions_with_plan_id, &Action.changeset(%Action{}, &1))

    if Enum.all?(changesets, & &1.valid?) do
      actions = Enum.map(changesets, &Repo.insert!/1)
      {:ok, actions}
    else
      invalid_changeset = Enum.find(changesets, &(not &1.valid?))
      {:error, invalid_changeset}
    end
  end

  # Private functions

  defp broadcast({:ok, plan} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:remediation_plan, action, plan)
    result
  end

  defp broadcast(result, _action), do: result
end
