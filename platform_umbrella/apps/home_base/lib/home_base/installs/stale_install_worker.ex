defmodule HomeBase.StaleInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  require Logger

  @me __MODULE__
  @state_opts [
    :delay
  ]

  typedstruct module: State do
    field :delay, integer(), default: 900_000
  end

  def start_link(args) do
    {state_opts, genserver_opts} = Keyword.split(args, @state_opts)

    GenServer.start_link(__MODULE__, state_opts, Keyword.merge([name: @me], genserver_opts))
  end

  @impl GenServer
  def init(args) do
    state = struct!(State, args)
    Logger.debug("Starting HomeBase.StaleInstallWorker")
    schedule_worker(state)
    {:ok, state}
  end

  @impl GenServer
  def handle_info(:delete_unstarted_installs, state) do
    Logger.info("Checking for unstarted installs to delete")
    to_delete = HomeBase.StaleInstalls.list_unstarted_installations()
    Logger.info("Found #{length(to_delete)} unstarted installs to delete")

    # Delete them
    Enum.each(to_delete, &HomeBase.StaleInstalls.delete_installation!/1)

    schedule_worker(state)
    {:noreply, state}
  end

  def schedule_worker(%{delay: delay}) do
    Process.send_after(self(), :delete_unstarted_installs, delay)
  end
end
