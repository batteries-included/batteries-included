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
    GenServer.start_link(
      __MODULE__,
      # Unless the user passed in a state summary this is where will
      # get the baseline state summary. It's important to do this early before
      # any other processes can be started. This ensures there is no race.
      Keyword.put_new_lazy(opts, :state_summary, &Summarizer.cached/0),

      # We never provide a name for ReconfigCanary; it's only purpose is to perish.
      []
    )
  end

  @impl GenServer
  @spec init(keyword()) :: {:ok, State.t()}
  def init(opts) do
    :ok = EventCenter.SystemStateSummary.subscribe()

    state = struct!(State, opts)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(%StateSummary{} = summary, %State{state_summary: old, methods: methods} = state) do
    if all_same(summary, old, methods) do
      Logger.debug("System state summary same as the previous summary, no reconfiguration with #{length(methods)}.")

      {:noreply, state}
    else
      Logger.info("System state summary has changed, reconfiguring system with #{length(methods)}")
      {:stop, :reconfigure_needed, state}
    end
  end

  defp all_same(%StateSummary{} = new, %StateSummary{} = old, methods) do
    Enum.all?(methods, &(do_try(new, &1) == do_try(old, &1)))
  end

  defp do_try(summary, method) do
    {nil, method.(summary)}
  rescue
    reason ->
      Logger.warning("Error in summary method reason: #{inspect(reason)}")
      {reason, nil}
  catch
    _ ->
      {true, nil}
  end
end
