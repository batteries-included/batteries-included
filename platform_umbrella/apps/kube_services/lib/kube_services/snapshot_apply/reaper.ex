defmodule KubeServices.SnapshotApply.Reaper do
  @moduledoc """
  This module is responsible for cleaning up old snapshots. It
  periodically finds all snapshots that are past the age and
  then deletes them. Reporting the clean up here.
  """

  use GenServer
  use TypedStruct

  alias ControlServer.SnapshotApply.Umbrella

  require Logger

  @state_arg_keys [:delay, :max_age]

  typedstruct module: State do
    # How often to check for old snapshots in milliseconds
    field :delay, pos_integer(), default: 1000 * 60 * 60
    # The max age of a snapshot in hours
    field :max_age, pos_integer(), default: 120
  end

  def start_link(args) do
    {state_args, gen_args} =
      args
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_arg_keys)

    GenServer.start_link(__MODULE__, state_args, gen_args)
  end

  @impl GenServer
  def init(init_arg) do
    state = struct!(State, init_arg)
    Logger.debug("Starting reaper with state: #{inspect(state)}")
    schedule_reap(state)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:reap, state) do
    deleted_count = Umbrella.reap_old_snapshots(state.max_age)
    deleted_doc_count = ControlServer.ContentAddressable.Reap.reap_unused_documents()
    Logger.info("Deleted #{deleted_count} snapshots and #{deleted_doc_count} documents that are not referenced.")
    schedule_reap(state)
    {:noreply, state}
  end

  defp schedule_reap(%State{delay: delay} = _state) do
    Process.send_after(self(), :reap, delay)
  end
end
