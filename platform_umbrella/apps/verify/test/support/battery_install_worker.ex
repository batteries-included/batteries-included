defmodule Verify.BatteryInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  import Wallaby.Browser

  alias CommonCore.Batteries.CatalogBattery
  alias Wallaby.Query

  require Logger

  typedstruct module: State do
    field :session, Wallaby.Session.t()
  end

  @state_opts ~w(session)a

  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(args) do
    state = struct!(State, args)

    Logger.info("Starting BatteryInstallWorker")

    {:ok, state}
  end

  def handle_call({:set_session, session}, _from, state) do
    {:reply, :ok, %{state | session: session}}
  end

  def handle_call(_, _from, %{session: nil} = state) do
    Logger.error("Tried to install battery without setting a session!")
    {:reply, :error, state}
  end

  def handle_call({:install_battery, battery}, _from, %{session: session} = state) do
    Logger.info("Installing battery: #{battery.name}")

    try do
      session
      |> visit("batteries/#{battery.group}/new/#{battery.type}")
      |> click(Query.text("Install Battery"))
      # click the only link - Done - in the modal
      |> find(Query.css("#install-modal-container"), &click(&1, Query.link("")))
      |> take_screenshot(name: "post_install_#{battery.type}")
    rescue
      e ->
        # grab a screenshot if we've failed to install the battery
        take_screenshot(session, name: "battery-install-worker-failure-#{battery.type}")

        reraise(e, __STACKTRACE__)
    end

    {:reply, :ok, state}
  end

  @spec set_session(GenServer.name(), Wallaby.Session.t()) :: term()
  def set_session(name, session) do
    GenServer.call(name, {:set_session, session})
  end

  @spec install_battery(GenServer.name(), CatalogBattery.t()) :: term()
  def install_battery(name, battery) do
    GenServer.call(name, {:install_battery, battery}, 5 * 60 * 1000)
  end
end
