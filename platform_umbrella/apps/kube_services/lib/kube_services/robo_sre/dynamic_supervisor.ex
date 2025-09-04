defmodule KubeServices.RoboSRE.DynamicSupervisor do
  @moduledoc """
  Dynamic supervisor for RoboSRE issue worker processes.

  Each issue gets its own worker process that manages its lifecycle
  from detection through resolution.
  """
  use DynamicSupervisor

  alias CommonCore.Batteries.SystemBattery

  def start_link(opts) do
    battery = Keyword.fetch!(opts, :battery)
    DynamicSupervisor.start_link(__MODULE__, battery, name: via_name(battery))
  end

  @impl DynamicSupervisor
  def init(%SystemBattery{} = _battery) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start an issue worker for the given issue.
  """
  def start_issue_worker(battery, issue) do
    child_spec = {KubeServices.RoboSRE.IssueWorker, issue: issue, battery: battery}
    DynamicSupervisor.start_child(via_name(battery), child_spec)
  end

  @doc """
  Stop an issue worker for the given issue.
  """
  def stop_issue_worker(battery, issue_id) do
    case Registry.lookup(KubeServices.RoboSRE.Registry, issue_id) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(via_name(battery), pid)

      [] ->
        :ok
    end
  end

  defp via_name(%SystemBattery{id: id}) do
    {:via, Registry, {KubeServices.Batteries.Registry, {id, __MODULE__}}}
  end
end
