defmodule KubeServices.SystemState.ReconfigCanary do
  @moduledoc """
  ReconfigCanary is a GenServer that will stop the system
  if the state summary is not the same as the previous summary
  for all provided methods. This is useful to cause a supervision
  tree to be restart if the state summary has changed.
  """
  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias KubeServices.SystemState.Summarizer

  require Logger

  typedstruct module: State do
    field :state_summary, StateSummary.t()
    field :methods, list(function())
  end

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  @spec init(keyword()) :: {:ok, State.t()}
  def init(opts) do
    :ok = EventCenter.SystemStateSummary.subscribe()

    methods = Keyword.get(opts, :methods, [])
    {:ok, %State{state_summary: Summarizer.cached(), methods: methods}}
  end

  @impl GenServer
  def handle_info(%CommonCore.StateSummary{} = summary, %State{state_summary: old, methods: methods} = state) do
    if all_same(summary, old, methods) do
      Logger.debug("System state summary is the same as the previous summary, no reconfiguration needed.")
      {:noreply, state}
    else
      Logger.info("System state summary has changed, reconfiguring system with #{length(methods)}")
      {:stop, :reconfigure_needed, state}
    end
  end

  defp all_same(%CommonCore.StateSummary{} = new, %CommonCore.StateSummary{} = old, methods) do
    Enum.all?(methods, &(do_try(new, &1) == do_try(old, &1)))
  end

  defp do_try(summary, method) do
    {nil, method.(summary)}
  rescue
    reason ->
      Logger.warning("Error in summary method #{method}, reason: #{inspect(reason)}")
      {reason, nil}
  catch
    _ ->
      {true, nil}
  end
end
