defmodule ControlServer.Services.PrometheusTest do
  use ExUnit.Case, async: true
  use ControlServer.DataCase

  alias ControlServer.Services.Prometheus

  def create do
    child_spec = %{
      id: PrometheusTest,
      start:
        {Prometheus, :start_link,
         [%{status: :starting, kube_client: %{}}, [name: PrometheusTest]]}
    }

    start_supervised!(child_spec)
  end

  describe "Prometheuds actor" do
    test "Prometheus starts up with a starting state" do
      pid = create()

      assert :starting == Prometheus.status(pid)
    end

    test "Can sync" do
      pid = create()
      assert :ok == Prometheus.sync(pid, %{})
    end

    test "can refresh configs" do
      files = Prometheus.refresh_db_configs()
      files_2 = Prometheus.refresh_db_configs()

      assert files == files_2
    end

    test "ignores already configured and running" do
      Prometheus.sync_operator(:running, %{}, %{})
    end
  end
end
