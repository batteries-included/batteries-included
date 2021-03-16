defmodule Server.Services.PrometheusTest do
  use ExUnit.Case, async: true
  use Server.DataCase

  alias Server.Services.Prometheus

  def create do
    child_spec = %{
      id: PrometheusTest,
      start: {Prometheus, :start_link, [[], [name: PrometheusTest]]}
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
  end
end
