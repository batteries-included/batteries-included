defmodule Verify.KindInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias Verify.PathHelper

  require Logger

  typedstruct module: State do
    field :bi_binary, :string
    field :root_path, :string
    field :started, :list, default: []
  end

  @state_opts ~w(bi_binary root_path)a

  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.put_new_lazy(:bi_binary, &PathHelper.find_bi/0)
      |> Keyword.put_new_lazy(:root_path, &PathHelper.root_path/0)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(args) do
    state = struct!(State, args)

    Logger.info("Starting KindInstallWorker with BI binary at #{state.bi_binary}")

    {:ok, state}
  end

  def handle_call({:start, path}, _from, state) do
    case do_start(state, path) do
      {_, 0} ->
        Logger.debug("Kind install started from #{path}")
        {:reply, :ok, %State{state | started: [path | state.started]}}

      respone ->
        Logger.warning("Unable to start Kind install from #{path}")
        {:reply, respone, state}
    end
  end

  def handle_call(:stop_all, _from, %{started: started} = state) do
    Enum.each(started, fn path ->
      :ok = do_stop(state, path)
    end)

    {:reply, :ok, %State{state | started: []}}
  end

  defp do_stop(state, path) do
    path = regularize_path(state, path)
    spec = path |> File.read!() |> Jason.decode!()
    slug = Map.fetch!(spec, "slug")

    Logger.info("Stopping Kind install with path = #{path} slug #{slug}")

    {_, 0} = System.cmd(state.bi_binary, ["stop", slug])
    :ok
  end

  defp do_start(state, path) do
    path = regularize_path(state, path)
    Logger.info("Starting Kind install from #{path}")

    System.cmd(state.bi_binary, ["start", path])
  end

  defp regularize_path(state, path) do
    if String.starts_with?(path, "/") do
      path
    else
      Path.join(state.root_path, path)
    end
  end

  def start(path) do
    GenServer.call(__MODULE__, {:start, path}, 15 * 60 * 1000)
  end

  def stop_all do
    GenServer.call(__MODULE__, :stop_all, 15 * 60 * 1000)
  end
end
