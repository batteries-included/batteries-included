defmodule CommonCore.K8s.LeaderElectionTest do
  use ExUnit.Case, async: false

  import Mox

  alias CommonCore.K8s.LeaderElection
  alias CommonCore.K8s.MockClient
  alias K8s.Client.APIError

  setup :verify_on_exit!
  setup :set_mox_from_context

  describe "start_link/1" do
    test "starts with valid configuration" do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock the K8s operations
      stub(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      stub(MockClient, :run, fn _, _ ->
        {:error, %APIError{reason: "NotFound"}}
      end)

      stub(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      stub(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      assert {:ok, pid} = LeaderElection.start_link(opts)
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "accepts custom callback functions" do
      callback_pid = self()

      # Create a mock connection function to bypass ConnectionPool
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_leader_with_callbacks,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func,
        on_started_leading: fn -> send(callback_pid, :started_leading) end,
        on_stopped_leading: fn -> send(callback_pid, :stopped_leading) end,
        on_new_leader: fn identity -> send(callback_pid, {:new_leader, identity}) end
      ]

      # Mock successful connection
      stub(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      stub(MockClient, :run, fn _, _ ->
        {:error, %APIError{reason: "NotFound"}}
      end)

      stub(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      stub(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      assert {:ok, pid} = LeaderElection.start_link(opts)
      assert Process.alive?(pid)

      # Give it time to initialize
      :timer.sleep(50)

      GenServer.stop(pid)
    end

    test "uses conn_func when provided instead of ConnectionPool" do
      # Create a mock connection
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_conn_func,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-conn-func",
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock the K8s operations
      stub(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      stub(MockClient, :run, fn _, _ ->
        {:error, %APIError{reason: "NotFound"}}
      end)

      stub(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      stub(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      # This should work without ConnectionPool being available
      assert {:ok, pid} = LeaderElection.start_link(opts)
      assert Process.alive?(pid)

      # Give it time to initialize
      :timer.sleep(50)

      GenServer.stop(pid)
    end
  end

  describe "leader election flow" do
    setup do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_leader_election,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        lease_duration: 1000,
        renew_deadline: 500,
        retry_period: 100,
        kube_client: MockClient,
        conn_func: conn_func
      ]

      %{opts: opts}
    end

    test "becomes leader when no existing leader", %{opts: opts} do
      # Mock no existing ConfigMap
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:error, %APIError{reason: "NotFound"}}
      end)

      # Mock successful creation
      expect(MockClient, :create, fn configmap ->
        # Verify the configmap structure
        assert configmap["kind"] == "ConfigMap"
        assert configmap["metadata"]["name"] == "test-lock"
        assert configmap["metadata"]["namespace"] == "default"

        leader_data = configmap["metadata"]["annotations"]["battery.election/leader"]
        leader_record = Jason.decode!(leader_data)
        assert leader_record["holderIdentity"] == "test-instance-1"

        %K8s.Operation{method: :post, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      # Mock apply for release_lock during terminate
      expect(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Give it time to attempt leadership
      :timer.sleep(150)

      assert LeaderElection.leader?(pid) == true
      assert LeaderElection.get_leader(pid) == "test-instance-1"

      GenServer.stop(pid)
    end

    test "does not become leader when another instance holds valid lease", %{opts: opts} do
      other_leader_record = %{
        "holderIdentity" => "other-instance",
        "leaseDurationSeconds" => 1,
        "acquireTime" => System.system_time(:millisecond),
        "renewTime" => System.system_time(:millisecond),
        "leaderTransitions" => 1
      }

      # Mock existing ConfigMap with valid lease
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok,
         %{
           "metadata" => %{
             "annotations" => %{
               "battery.election/leader" => Jason.encode!(other_leader_record)
             }
           }
         }}
      end)

      # Mock get for subsequent attempts (it retries)
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok,
         %{
           "metadata" => %{
             "annotations" => %{
               "battery.election/leader" => Jason.encode!(other_leader_record)
             }
           }
         }}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Give it time to check leadership
      :timer.sleep(150)

      assert LeaderElection.leader?(pid) == false
      assert LeaderElection.get_leader(pid) == "other-instance"

      GenServer.stop(pid)
    end

    test "acquires leadership when existing lease expires", %{opts: opts} do
      # Create expired lease record
      expired_time = System.system_time(:millisecond) - 2000

      expired_record = %{
        "holderIdentity" => "expired-instance",
        "leaseDurationSeconds" => 1,
        "acquireTime" => expired_time,
        "renewTime" => expired_time,
        "leaderTransitions" => 1
      }

      # Mock getting expired ConfigMap
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok,
         %{
           "metadata" => %{
             "annotations" => %{
               "battery.election/leader" => Jason.encode!(expired_record)
             }
           }
         }}
      end)

      # Mock successful acquisition
      expect(MockClient, :apply, fn configmap ->
        leader_data = configmap["metadata"]["annotations"]["battery.election/leader"]
        leader_record = Jason.decode!(leader_data)

        # Should increment transitions and set new identity
        assert leader_record["holderIdentity"] == "test-instance-1"
        assert leader_record["leaderTransitions"] == 2

        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      # Mock apply for release_lock during terminate
      expect(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Give it time to acquire leadership
      :timer.sleep(150)

      assert LeaderElection.leader?(pid) == true
      assert LeaderElection.get_leader(pid) == "test-instance-1"

      GenServer.stop(pid)
    end

    test "renews leadership when already leader", %{opts: opts} do
      current_time = System.system_time(:millisecond)

      # Create record showing this instance as leader
      leader_record = %{
        "holderIdentity" => "test-instance-1",
        "leaseDurationSeconds" => 1,
        "acquireTime" => current_time,
        "renewTime" => current_time,
        "leaderTransitions" => 1
      }

      # Mock getting current leadership record (2 calls - initial and renewal)
      expect(MockClient, :get, 2, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, 2, fn _, _ ->
        {:ok,
         %{
           "metadata" => %{
             "annotations" => %{
               "battery.election/leader" => Jason.encode!(leader_record)
             }
           }
         }}
      end)

      # Mock create in case it tries to create initially
      expect(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      # Mock successful renewal
      expect(MockClient, :apply, fn configmap ->
        leader_data = configmap["metadata"]["annotations"]["battery.election/leader"]
        leader_record = Jason.decode!(leader_data)

        # Should maintain same transitions and identity but update renew time
        assert leader_record["holderIdentity"] == "test-instance-1"
        assert leader_record["leaderTransitions"] == 1

        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      # Mock apply for release_lock during terminate
      expect(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Give it time to become leader and attempt renewal
      # Should trigger renewal before lease expires
      :timer.sleep(600)

      assert LeaderElection.leader?(pid) == true

      GenServer.stop(pid)
    end

    test "loses leadership on renewal failure", %{opts: opts} do
      current_time = System.system_time(:millisecond)

      # Initially this instance is leader
      initial_record = %{
        "holderIdentity" => "test-instance-1",
        "leaseDurationSeconds" => 1,
        "acquireTime" => current_time,
        "renewTime" => current_time,
        "leaderTransitions" => 1
      }

      # Use stubs for more flexibility
      stub(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      # Use a counter to control when renewal fails
      Agent.start_link(fn -> 0 end, name: :renewal_fail_counter)

      stub(MockClient, :run, fn _, operation ->
        case operation.method do
          :get ->
            # Always return this instance as leader initially
            {:ok,
             %{
               "metadata" => %{
                 "annotations" => %{
                   "battery.election/leader" => Jason.encode!(initial_record)
                 }
               }
             }}

          :patch ->
            # First renewal succeeds, then fail
            count = Agent.get_and_update(:renewal_fail_counter, &{&1, &1 + 1})

            case count do
              # First renewal succeeds
              0 -> {:ok, %{"metadata" => %{"name" => "test-lock"}}}
              # Then fail
              _ -> {:error, %APIError{reason: "Conflict"}}
            end
        end
      end)

      stub(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Give it time to become leader and fail renewal
      :timer.sleep(600)

      # Should lose leadership after failed renewal
      assert LeaderElection.leader?(pid) == false

      GenServer.stop(pid)
      Agent.stop(:renewal_fail_counter)
    end
  end

  describe "release_leadership/1" do
    test "releases leadership gracefully" do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_release_leader,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock becoming leader first
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:error, %APIError{reason: "NotFound"}}
      end)

      expect(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      # Mock releasing leadership
      expect(MockClient, :apply, fn configmap ->
        leader_data = configmap["metadata"]["annotations"]["battery.election/leader"]
        leader_record = Jason.decode!(leader_data)

        # Should release by setting empty identity and short lease
        assert leader_record["holderIdentity"] == ""
        assert leader_record["leaseDurationSeconds"] == 1

        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Give it time to become leader
      :timer.sleep(150)

      assert LeaderElection.leader?(pid) == true

      # Release leadership
      assert :ok = LeaderElection.release_leadership(pid)
      assert LeaderElection.leader?(pid) == false

      GenServer.stop(pid)
    end

    test "handles release when not leader" do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_not_leader_release,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock not becoming leader
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok,
         %{
           "metadata" => %{
             "annotations" => %{
               "battery.election/leader" =>
                 Jason.encode!(%{
                   "holderIdentity" => "other-instance",
                   "leaseDurationSeconds" => 1,
                   "acquireTime" => System.system_time(:millisecond),
                   "renewTime" => System.system_time(:millisecond),
                   "leaderTransitions" => 1
                 })
             }
           }
         }}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Give it time to check leadership
      :timer.sleep(150)

      assert LeaderElection.leader?(pid) == false

      # Should not attempt to release when not leader
      assert :ok = LeaderElection.release_leadership(pid)

      GenServer.stop(pid)
    end
  end

  describe "callbacks" do
    test "calls on_started_leading when becoming leader" do
      test_pid = self()

      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_started_callback,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func,
        on_started_leading: fn -> send(test_pid, :started_leading_called) end
      ]

      # Mock becoming leader
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:error, %APIError{reason: "NotFound"}}
      end)

      expect(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      # Mock apply for release_lock during terminate
      expect(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Should receive callback
      assert_receive :started_leading_called, 1000

      GenServer.stop(pid)
    end

    test "calls on_stopped_leading when losing leadership" do
      test_pid = self()

      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_stopped_callback,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        lease_duration: 500,
        renew_deadline: 250,
        retry_period: 100,
        kube_client: MockClient,
        conn_func: conn_func,
        on_stopped_leading: fn -> send(test_pid, :stopped_leading_called) end
      ]

      current_time = System.system_time(:millisecond)

      # Initially not a leader
      stub(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      stub(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      # Use a counter to control the flow: create -> acquire -> lose
      Agent.start_link(fn -> 0 end, name: :renewal_counter)

      stub(MockClient, :run, fn _, operation ->
        case operation.method do
          :get ->
            count = Agent.get(:renewal_counter, & &1)

            case count do
              0 ->
                # No configmap exists initially
                {:error, %APIError{reason: "NotFound"}}

              _ ->
                # After creation, we are the leader
                {:ok,
                 %{
                   "metadata" => %{
                     "annotations" => %{
                       "battery.election/leader" =>
                         Jason.encode!(%{
                           "holderIdentity" => "test-instance-1",
                           "leaseDurationSeconds" => 1,
                           "acquireTime" => current_time,
                           "renewTime" => current_time,
                           "leaderTransitions" => 1
                         })
                     }
                   }
                 }}
            end

          :post ->
            # Successfully create the lock (become leader)
            Agent.update(:renewal_counter, &(&1 + 1))
            {:ok, %{"metadata" => %{"name" => "test-lock"}}}

          :patch ->
            # First renewal succeeds, then fail to lose leadership
            count = Agent.get_and_update(:renewal_counter, &{&1, &1 + 1})

            case count do
              # First renewal succeeds
              1 -> {:ok, %{"metadata" => %{"name" => "test-lock"}}}
              # Then fail to lose leadership
              _ -> {:error, %APIError{reason: "Conflict"}}
            end
        end
      end)

      # Renewal attempts will use apply
      stub(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Should lose leadership and receive callback
      assert_receive :stopped_leading_called, 2000

      GenServer.stop(pid)
      Agent.stop(:renewal_counter)
    end

    test "calls on_new_leader when observing different leader" do
      test_pid = self()

      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_new_leader_callback,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func,
        on_new_leader: fn identity -> send(test_pid, {:new_leader, identity}) end
      ]

      # Mock observing another leader
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok,
         %{
           "metadata" => %{
             "annotations" => %{
               "battery.election/leader" =>
                 Jason.encode!(%{
                   "holderIdentity" => "other-instance",
                   "leaseDurationSeconds" => 1,
                   "acquireTime" => System.system_time(:millisecond),
                   "renewTime" => System.system_time(:millisecond),
                   "leaderTransitions" => 1
                 })
             }
           }
         }}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Should receive new leader callback
      assert_receive {:new_leader, "other-instance"}, 1000

      GenServer.stop(pid)
    end
  end

  describe "error handling" do
    test "handles K8s connection errors gracefully" do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_connection_error,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        retry_period: 100,
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock connection error (multiple retries expected)
      expect(MockClient, :get, 2, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, 2, fn _, _ ->
        {:error, %K8s.Client.HTTPError{message: "Connection refused"}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Should remain a follower but not crash
      :timer.sleep(150)
      assert Process.alive?(pid)
      assert LeaderElection.leader?(pid) == false

      GenServer.stop(pid)
    end

    test "handles malformed leader records" do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_malformed_record,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock ConfigMap with malformed leader data
      expect(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok,
         %{
           "metadata" => %{
             "annotations" => %{
               "battery.election/leader" => "invalid-json"
             }
           }
         }}
      end)

      # Should attempt to create new record
      expect(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      # Mock apply for release_lock during terminate
      expect(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      expect(MockClient, :run, fn _, _ ->
        {:ok, %{"metadata" => %{"name" => "test-lock"}}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Should handle gracefully and attempt to become leader
      :timer.sleep(150)
      assert LeaderElection.leader?(pid) == true

      GenServer.stop(pid)
    end
  end

  describe "edge cases" do
    test "handles rapid start/stop cycles" do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock basic operations
      stub(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      stub(MockClient, :run, fn _, _ ->
        {:error, %APIError{reason: "NotFound"}}
      end)

      stub(MockClient, :create, fn _ ->
        %K8s.Operation{method: :post, path_params: []}
      end)

      stub(MockClient, :apply, fn _ ->
        %K8s.Operation{method: :patch, path_params: []}
      end)

      # Start and stop multiple times rapidly
      for _i <- 1..5 do
        {:ok, pid} = LeaderElection.start_link(opts)
        :timer.sleep(10)
        GenServer.stop(pid)
      end
    end

    test "handles process termination during operations" do
      # Create a mock connection function
      mock_conn = %K8s.Conn{
        cluster_name: "test-cluster",
        user_name: "test-user",
        url: "https://test-k8s-api:6443"
      }

      conn_func = fn -> mock_conn end

      opts = [
        name: :test_termination,
        lock_name: "test-lock",
        namespace: "default",
        identity: "test-instance-1",
        kube_client: MockClient,
        conn_func: conn_func
      ]

      # Mock slow K8s operation - use stub since we might terminate before calls complete
      stub(MockClient, :get, fn _, _, _ ->
        %K8s.Operation{method: :get, path_params: []}
      end)

      stub(MockClient, :run, fn _, _ ->
        # Long delay
        :timer.sleep(1000)
        {:error, %APIError{reason: "NotFound"}}
      end)

      {:ok, pid} = LeaderElection.start_link(opts)

      # Terminate quickly
      GenServer.stop(pid)

      refute Process.alive?(pid)
    end
  end
end
