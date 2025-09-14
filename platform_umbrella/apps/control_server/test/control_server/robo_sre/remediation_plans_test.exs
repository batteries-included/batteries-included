defmodule ControlServer.RoboSRE.RemediationPlansTest do
  use ControlServer.DataCase

  import ControlServer.Factory

  alias CommonCore.RoboSRE.Action
  alias CommonCore.RoboSRE.RemediationPlan
  alias ControlServer.RoboSRE.RemediationPlans

  describe "remediation_plans" do
    test "list_remediation_plans/0 returns all remediation plans" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)
      assert RemediationPlans.list_remediation_plans() == [plan]
    end

    test "get_remediation_plan!/1 returns the plan with given id" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)
      fetched_plan = RemediationPlans.get_remediation_plan!(plan.id)

      assert fetched_plan.id == plan.id
      assert fetched_plan.issue_id == plan.issue_id
      assert fetched_plan.retry_delay_ms == plan.retry_delay_ms
      assert fetched_plan.success_delay_ms == plan.success_delay_ms
      assert fetched_plan.max_retries == plan.max_retries
      assert fetched_plan.current_action_index == plan.current_action_index
    end

    test "get_remediation_plan/1 returns the plan with given id" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)
      fetched_plan = RemediationPlans.get_remediation_plan(plan.id)

      assert fetched_plan.id == plan.id
      assert fetched_plan.issue_id == plan.issue_id
      assert fetched_plan.retry_delay_ms == plan.retry_delay_ms
      assert fetched_plan.success_delay_ms == plan.success_delay_ms
      assert fetched_plan.max_retries == plan.max_retries
      assert fetched_plan.current_action_index == plan.current_action_index
    end

    test "get_remediation_plan/1 returns nil for non-existent id" do
      non_existent_id = Ecto.UUID.generate()
      assert RemediationPlans.get_remediation_plan(non_existent_id) == nil
    end

    test "create_remediation_plan/1 with valid data creates a plan" do
      issue = insert(:issue)

      valid_attrs = %{
        issue_id: issue.id,
        retry_delay_ms: 30_000,
        success_delay_ms: 10_000,
        max_retries: 2,
        current_action_index: 0
      }

      assert {:ok, %RemediationPlan{} = plan} = RemediationPlans.create_remediation_plan(valid_attrs)
      assert plan.issue_id == issue.id
      assert plan.retry_delay_ms == 30_000
      assert plan.success_delay_ms == 10_000
      assert plan.max_retries == 2
      assert plan.current_action_index == 0
    end

    test "create_remediation_plan/1 with actions" do
      issue = insert(:issue)

      valid_attrs = %{
        issue_id: issue.id,
        retry_delay_ms: 30_000,
        success_delay_ms: 10_000,
        max_retries: 2,
        actions: [
          %{
            action_type: :delete_resource,
            params: %{"name" => "test-pod"},
            order_index: 0
          },
          %{
            action_type: :restart_kube_state,
            params: %{},
            order_index: 1
          }
        ]
      }

      assert {:ok, %RemediationPlan{} = plan} = RemediationPlans.create_remediation_plan(valid_attrs)
      assert plan.issue_id == issue.id
      assert length(plan.actions) == 2
    end

    test "create_remediation_plan/1 with invalid data returns error changeset" do
      issue = insert(:issue)

      invalid_attrs = %{
        issue_id: issue.id,
        # Invalid: must be greater than 0
        retry_delay_ms: -1,
        # Invalid: must be greater than or equal to 0
        max_retries: -1
      }

      assert {:error, %Ecto.Changeset{}} = RemediationPlans.create_remediation_plan(invalid_attrs)
    end

    test "update_remediation_plan/2 with valid data updates the plan" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id, max_retries: 3)

      update_attrs = %{
        max_retries: 5,
        current_action_index: 1
      }

      assert {:ok, %RemediationPlan{} = updated_plan} = RemediationPlans.update_remediation_plan(plan, update_attrs)
      assert updated_plan.max_retries == 5
      assert updated_plan.current_action_index == 1
    end

    test "update_remediation_plan/2 with invalid data returns error changeset" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)
      invalid_attrs = %{max_retries: -1}

      assert {:error, %Ecto.Changeset{}} = RemediationPlans.update_remediation_plan(plan, invalid_attrs)

      # Verify the plan wasn't updated
      unchanged_plan = RemediationPlans.get_remediation_plan!(plan.id)
      assert unchanged_plan.max_retries == plan.max_retries
    end

    test "delete_remediation_plan/1 deletes the plan" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)
      assert {:ok, %RemediationPlan{}} = RemediationPlans.delete_remediation_plan(plan)
      assert_raise Ecto.NoResultsError, fn -> RemediationPlans.get_remediation_plan!(plan.id) end
    end

    test "change_remediation_plan/1 returns a remediation plan changeset" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)
      assert %Ecto.Changeset{} = RemediationPlans.change_remediation_plan(plan)
    end

    test "update_action_result/2 updates action result and executed_at timestamp" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)
      action = insert(:action, remediation_plan_id: plan.id, result: nil, executed_at: nil)

      result = %{
        "success" => true,
        "message" => "Action completed successfully",
        "details" => %{"pods_deleted" => 1}
      }

      assert {:ok, %Action{} = updated_action} = RemediationPlans.update_action_result(action.id, result)
      assert updated_action.result == result
      assert updated_action.executed_at
      assert DateTime.diff(updated_action.executed_at, DateTime.utc_now(), :second) < 5
    end

    test "update_action_result/2 with invalid action id returns error" do
      non_existent_id = Ecto.UUID.generate()
      result = %{"success" => false}

      # When no action is found, the function returns an error due to the nil being passed to changeset
      assert_raise KeyError, fn ->
        RemediationPlans.update_action_result(non_existent_id, result)
      end
    end

    test "find_remediation_plans_by_issue/1 returns plans for specific issue" do
      issue1 = insert(:issue)
      issue2 = insert(:issue)

      # Create plans for different issues
      plan1 = insert(:remediation_plan, issue_id: issue1.id)
      plan2 = insert(:remediation_plan, issue_id: issue1.id)
      _plan3 = insert(:remediation_plan, issue_id: issue2.id)

      # Insert in reverse order to test the desc ordering
      :timer.sleep(1)
      plan4 = insert(:remediation_plan, issue_id: issue1.id)

      plans = RemediationPlans.find_remediation_plans_by_issue(issue1.id)

      assert length(plans) == 3
      # Should be ordered by inserted_at desc (newest first)
      plan_ids = Enum.map(plans, & &1.id)
      assert plan4.id == Enum.at(plan_ids, 0)
      assert plan2.id in plan_ids
      assert plan1.id in plan_ids
    end

    test "find_remediation_plans_by_issue/1 with preload option includes actions" do
      issue = insert(:issue)
      plan = insert(:remediation_plan, issue_id: issue.id)

      action1 = insert(:action, remediation_plan_id: plan.id, order_index: 0)
      action2 = insert(:action, remediation_plan_id: plan.id, order_index: 1)

      [found_plan] = RemediationPlans.find_remediation_plans_by_issue(issue.id, preload: [:actions])

      assert found_plan.id == plan.id
      assert Ecto.assoc_loaded?(found_plan.actions)
      assert length(found_plan.actions) == 2

      # Actions should be ordered by order_index (from the preload_order in the schema)
      action_ids = Enum.map(found_plan.actions, & &1.id)
      assert action_ids == [action1.id, action2.id]
    end

    test "find_remediation_plans_by_issue/1 returns empty list for issue with no plans" do
      issue = insert(:issue)
      plans = RemediationPlans.find_remediation_plans_by_issue(issue.id)
      assert plans == []
    end

    test "create_remediation_plan/1 with actions creates actions with correct remediation_plan_id" do
      issue = insert(:issue)

      # Create plan first without actions
      {:ok, plan} =
        RemediationPlans.create_remediation_plan(%{
          issue_id: issue.id,
          retry_delay_ms: 30_000,
          success_delay_ms: 10_000,
          max_retries: 2
        })

      # Then create actions separately (this mimics how they're actually used in the app)
      action =
        insert(:action,
          remediation_plan_id: plan.id,
          action_type: :delete_resource,
          params: %{"name" => "test-pod"},
          order_index: 0
        )

      # Verify the action was created and associated correctly
      actions = Repo.all(from(a in Action, where: a.remediation_plan_id == ^plan.id))
      assert length(actions) == 1

      found_action = List.first(actions)
      assert found_action.id == action.id
      assert found_action.remediation_plan_id == plan.id
      assert found_action.action_type == :delete_resource
      assert found_action.params == %{"name" => "test-pod"}
      assert found_action.order_index == 0
    end

    test "create_remediation_plan/1 handles empty actions list" do
      issue = insert(:issue)

      valid_attrs = %{
        issue_id: issue.id,
        retry_delay_ms: 30_000,
        success_delay_ms: 10_000,
        max_retries: 2,
        actions: []
      }

      {:ok, plan} = RemediationPlans.create_remediation_plan(valid_attrs)
      assert plan.issue_id == issue.id

      # Verify no actions were created
      actions = Repo.all(from(a in Action, where: a.remediation_plan_id == ^plan.id))
      assert length(actions) == 0
    end

    test "create_remediation_plan/1 creates plan and allows separate action creation" do
      issue = insert(:issue)

      # Create plan without actions
      {:ok, plan} =
        RemediationPlans.create_remediation_plan(%{
          issue_id: issue.id,
          retry_delay_ms: 30_000,
          success_delay_ms: 10_000,
          max_retries: 2
        })

      # Create actions separately with the same order_index
      action1 = insert(:action, remediation_plan_id: plan.id, params: %{"name" => "test-pod-1"}, order_index: 0)
      action2 = insert(:action, remediation_plan_id: plan.id, params: %{"name" => "test-pod-2"}, order_index: 0)

      actions = Repo.all(from(a in Action, where: a.remediation_plan_id == ^plan.id, order_by: :inserted_at))

      assert length(actions) == 2
      assert Enum.all?(actions, &(&1.order_index == 0))
      assert action1.id in Enum.map(actions, & &1.id)
      assert action2.id in Enum.map(actions, & &1.id)
    end
  end
end
