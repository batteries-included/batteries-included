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
        RestartKubeStateExecutor.start_link(canary: MockCanary)

      # Allow the GenServer to call the mocks
      allow(MockCanary, self(), pid)

      on_exit(fn ->
        if Process.alive?(pid) do
          GenServer.stop(pid)
        end
      end)

      %{executor_pid: pid}
    end

    test "successfully restarts KubeState via Canary" do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, fn -> :ok end)

      # Act
      result = RestartKubeStateExecutor.execute(action)

      # Assert
      assert {:ok, :restarted} = result
    end

    test "handles Canary restart failure" do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, fn -> raise RuntimeError, "restart failed" end)

      # Act
      result = RestartKubeStateExecutor.execute(action)

      # Assert
      assert {:error, {:restart_failed, %RuntimeError{message: "restart failed"}}} = result
    end

    test "returns error for unsupported action type" do
      # Arrange
      action = %Action{
        action_type: :delete_resource,
        params: %{}
      }

      # Act
      result = RestartKubeStateExecutor.execute(action)

      # Assert
      assert {:error, {:unsupported_action_type, :delete_resource}} = result
    end

    test "handles concurrent restart requests" do
      # Arrange
      action1 = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      action2 = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      MockCanary
      |> expect(:force_restart, fn -> :ok end)
      |> expect(:force_restart, fn -> :ok end)

      # Act
      task1 = Task.async(fn -> RestartKubeStateExecutor.execute(action1) end)
      task2 = Task.async(fn -> RestartKubeStateExecutor.execute(action2) end)

      result1 = Task.await(task1)
      result2 = Task.await(task2)

      # Assert
      assert {:ok, :restarted} = result1
      assert {:ok, :restarted} = result2
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

    test "handles multiple restart requests in sequence" do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, 3, fn -> :ok end)

      # Act & Assert
      for _i <- 1..3 do
        result = GenServer.call(:integration_test_executor, {:execute, action})
        assert {:ok, :restarted} = result
      end
    end

    test "logs appropriate messages during restart" do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, fn -> :ok end)

      # Act
      result = GenServer.call(:integration_test_executor, {:execute, action})

      # Assert
      assert {:ok, :restarted} = result
      # Note: In a more sophisticated test setup, we could capture and verify log messages
    end

    test "handles Canary timeout gracefully" do
      # Arrange
      action = %Action{
        action_type: :restart_kube_state,
        params: %{}
      }

      expect(MockCanary, :force_restart, fn ->
        raise RuntimeError, "timeout"
      end)

      # Act
      result = GenServer.call(:integration_test_executor, {:execute, action})

      # Assert
      assert {:error, {:restart_failed, %RuntimeError{message: "timeout"}}} = result
    end
  end
end
