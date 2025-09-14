defmodule KubeServices.RoboSRE.RestartKubeStateExecutor do
  @moduledoc false

  @behaviour KubeServices.RoboSRE.Executor

  alias CommonCore.RoboSRE.Action

  def execute(%Action{action_type: :restart_kube_state}) do
    _ = KubeServices.KubeState.Canary.force_restart()
    {:ok, :restarted}
  end
end
