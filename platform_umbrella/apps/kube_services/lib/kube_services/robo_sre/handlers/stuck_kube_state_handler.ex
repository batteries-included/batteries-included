defmodule KubeServices.RoboSRE.StuckKubeStateHandler do
  @moduledoc false

  @behaviour KubeServices.RoboSRE.Handler

  alias CommonCore.RoboSRE.Issue
  alias CommonCore.RoboSRE.RemediationPlan

  def preflight(%Issue{issue_type: :stuck_kubestate} = _issue) do
    # For now we always return ready
    # Restartting the kube state is a pretty safe operation
    {:ok, :ready}
  end

  def preflight(_) do
    {:error, :invalid_issue_type}
  end

  def plan(%Issue{issue_type: :stuck_kubestate} = _issue) do
    {:ok, RemediationPlan.restart_kube_state()}
  end

  def verify(%Issue{issue_type: :stuck_kubestate} = _issue) do
    {:ok, :resolved}
  end
end
