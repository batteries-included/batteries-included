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
    actions = Map.get(attrs, :actions, [])

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:remediation_plan, RemediationPlan.changeset(%RemediationPlan{}, Map.delete(attrs, :actions)))
    |> Ecto.Multi.insert_all(:actions, Action, fn %{remediation_plan: plan} ->
      actions
      |> Enum.with_index()
      |> Enum.map(fn {a, index} ->
        a
        |> CommonCore.Util.Map.from_struct()
        |> Map.put(:remediation_plan_id, plan.id)
        |> Map.put(:inserted_at, DateTime.utc_now())
        |> Map.put_new(:order_index, index)
        |> Map.put(:updated_at, DateTime.utc_now())
        |> Map.put(:id, BatteryUUID.autogenerate())
      end)
    end)
    |> Multi.one(:fetched_plan, fn %{remediation_plan: plan} ->
      from RemediationPlan, where: [id: ^plan.id], preload: [:actions]
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{fetched_plan: plan}} -> {:ok, plan}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
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

  @spec update_action_result(BatteryUUID.t(), map()) :: {:ok, Action.t()} | {:error, Ecto.Changeset.t()}
  def update_action_result(action_id, result) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:action, from(a in Action, where: a.id == ^action_id))
    |> Ecto.Multi.update(:update_action, fn %{action: action} ->
      Action.changeset(action, %{result: result, executed_at: DateTime.utc_now()})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_action: updated_action}} -> {:ok, updated_action}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end

  @spec find_remediation_plans_by_issue(BatteryUUID.t()) :: [RemediationPlan.t()]
  def find_remediation_plans_by_issue(issue_id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [:actions])

    Repo.all(
      from(p in RemediationPlan,
        where: p.issue_id == ^issue_id,
        order_by: [desc: :inserted_at],
        preload: ^preload
      )
    )
  end

  # Private functions

  defp broadcast({:ok, plan} = result, action) do
    :ok = DatabaseEventCenter.broadcast(:remediation_plan, action, plan)
    result
  end

  defp broadcast(result, _action), do: result
end
