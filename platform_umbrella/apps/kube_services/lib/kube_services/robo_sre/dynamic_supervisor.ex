defmodule KubeServices.RoboSRE.DynamicSupervisor do
  @moduledoc """
  Dynamic supervisor for RoboSRE issue worker processes.

  Each issue gets its own worker process that manages its lifecycle
  from detection through resolution.
  """
  use DynamicSupervisor

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start an issue worker for the given issue.
  """
  def start_worker(opts \\ []) do
    child_spec = {KubeServices.RoboSRE.IssueWorker, opts}
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
