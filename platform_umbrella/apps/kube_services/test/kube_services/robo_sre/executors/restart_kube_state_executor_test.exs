defmodule KubeServices.RoboSRE.RestartKubeStateExecutorTest do
  use ExUnit.Case, async: false

  import Mox

  alias CommonCore.RoboSRE.Action
  alias KubeServices.KubeState.MockCanary
  alias KubeServices.RoboSRE.RestartKubeStateExecutor

  setup :verify_on_exit!

  describe "start_link/1" do
    test "starts the GenServer with default modules" do
      assert {:ok, pid} = RestartKubeStateExecutor.start_link(name: :test_executor)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "starts the GenServer with custom modules" do
      assert {:ok, pid} =
               RestartKubeStateExecutor.start_link(
                 name: :test_executor_custom,
                 canary: MockCanary
               )

      assert Process.alive?(pid)
      GenServer.stop(pid)
    end
  end

  describe "execute/1" do
    setup do
      # Start the GenServer with the default name so execute/1 can find it
      {:ok, pid} =
        RestartKubeStateExecutor.start_link(
          canary: MockCanary,
          name: KubeServices.RoboSRE.RestartKubeStateExecutorTest.Executor
        )

      # Allow the GenServer to call the mocks
      allow(MockCanary, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{executor_pid: pid}
    end

    test "successfully restarts KubeState via Canary", %{executor_pid: pid} do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, fn -> :ok end)

      # Act
      result = RestartKubeStateExecutor.execute(pid, action)

      # Assert
      assert {:ok, :restarted} = result
    end

    test "handles Canary restart failure", %{executor_pid: pid} do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, fn -> raise RuntimeError, "restart failed" end)

      # Act
      result = RestartKubeStateExecutor.execute(pid, action)

      # Assert
      assert {:error, {:restart_failed, %RuntimeError{message: "restart failed"}}} = result
    end

    test "returns error for unsupported action type", %{executor_pid: pid} do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{}
      }

      # Act
      result = RestartKubeStateExecutor.execute(pid, action)

      # Assert
      assert {:error, {:unsupported_action_type, :delete_resource}} = result
    end
  end

  describe "integration scenarios" do
    setup do
      # Start with unique name for integration tests to avoid conflicts
      {:ok, pid} =
        RestartKubeStateExecutor.start_link(
          name: :integration_test_executor,
          canary: MockCanary
        )

      # Allow the GenServer to call the mocks
      allow(MockCanary, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{executor_pid: pid}
    end

    test "handles Canary timeout gracefully", %{executor_pid: pid} do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, fn ->
        raise RuntimeError, "timeout"
      end)

      # Act
      result = RestartKubeStateExecutor.execute(pid, action)

      # Assert
      assert {:error, {:restart_failed, %RuntimeError{message: "timeout"}}} = result
    end
  end
end
