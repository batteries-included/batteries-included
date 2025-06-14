defmodule Verify.BatteryInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  import Verify.TestCase.Helpers
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
    Logger.error("Tried to install / uninstall battery without setting a session!")
    {:reply, :error, state}
  end

  def handle_call({:install_battery, battery, config}, _from, %{session: session} = state) do
    Logger.info("Installing battery: #{battery.name}")

    try do
      session
      |> visit("batteries/#{battery.group}/new/#{battery.type}")
      |> maybe_add_config(config)
      |> click(Query.text("Install Battery"))
      # we have to pause a bit here for the install to actually take
      |> sleep(1_000)
      |> visit("batteries/#{battery.group}")
      |> assert_has(Query.css("##{battery.type}", text: "ACTIVE"))
    rescue
      e ->
        # grab a screenshot if we've failed to install the battery
        take_screenshot(session, name: "battery-install-worker-failure-#{battery.type}")

        reraise(e, __STACKTRACE__)
    end

    {:reply, :ok, state}
  end

  def handle_call({:uninstall_battery, battery}, _from, %{session: session} = state) do
    Logger.info("Uninstalling battery: #{battery.name}")

    try do
      session
      |> visit("batteries/#{battery.group}")
      |> find(type_id_query(battery), &click(&1, Query.link("Edit")))
      |> accept_confirm(&click(&1, Query.button("Uninstall")))

      session
      |> visit("batteries/#{battery.group}")
      |> assert_has(type_id_query(battery, text: "Install"))
      |> trigger_k8s_deploy()
    rescue
      e ->
        # grab a screenshot if we've failed to install the battery
        take_screenshot(session, name: "battery-uninstall-worker-failure-#{battery.type}")

        reraise(e, __STACKTRACE__)
    end

    {:reply, :ok, state}
  end

  defp type_id_query(battery, opts \\ []), do: Query.css("##{battery.type}", opts)

  defp maybe_add_config(session, config) do
    Enum.reduce(config, session, fn {key, val}, acc ->
      fill_in_name(acc, "battery_config[#{Atom.to_string(key)}]", val)
    end)
  end

  @spec set_session(GenServer.name(), Wallaby.Session.t()) :: term()
  def set_session(name, session) do
    GenServer.call(name, {:set_session, session})
  end

  @spec install_battery(GenServer.name(), CatalogBattery.t(), map()) :: term()
  def install_battery(name, battery, config \\ %{}) do
    GenServer.call(name, {:install_battery, battery, config}, 5 * 60 * 1000)
  end

  @spec uninstall_battery(GenServer.name(), CatalogBattery.t()) :: term()
  def uninstall_battery(name, battery) do
    GenServer.call(name, {:uninstall_battery, battery}, 5 * 60 * 1000)
  end
end
