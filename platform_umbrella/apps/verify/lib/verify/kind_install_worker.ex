defmodule Verify.KindInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Ecto.BatteryUUID
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
      |> Keyword.put_new_lazy(:root_path, &PathHelper.tmp_dir!/0)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(args) do
    state = struct!(State, args)

    Logger.info("Starting KindInstallWorker with BI binary at #{state.bi_binary}")

    {:ok, state}
  end

  def handle_call({:start, identifier}, _from, state) do
    path = build_install_spec(identifier, state)

    case System.cmd(state.bi_binary, ["start", path]) do
      {output, 0} ->
        Logger.debug("Kind install started from #{path}")

        {:reply, {:ok, extract_url(output)}, %{state | started: [path | state.started]}}

      response ->
        Logger.warning("Unable to start Kind install from #{path}")
        {:reply, response, state}
    end
  end

  def handle_call(:stop_all, _from, %{started: started} = state) do
    Enum.each(started, fn path ->
      :ok = do_stop(state, path)
    end)

    {:reply, :ok, %{state | started: []}}
  end

  defp do_stop(state, path) do
    spec = path |> File.read!() |> Jason.decode!()
    slug = Map.fetch!(spec, "slug")

    Logger.info("Stopping Kind install with path = #{path} slug #{slug}")

    {_, 0} = System.cmd(state.bi_binary, ["stop", slug])

    # Remove the file after stopping the install
    _ = File.rm_rf(path)
    :ok
  end

  def build_install_spec(identifier, %{root_path: root_dir} = _state) do
    install = CommonCore.Installs.Generator.build(Verify.Installs.Generator, identifier)
    spec = CommonCore.InstallSpec.new!(install)
    id = BatteryUUID.autogenerate()
    path = Path.join(root_dir, "#{id}_#{install.slug}.spec.json")
    string = Jason.encode_to_iodata!(spec, pretty: true, escape: :javascript_safe)
    File.write!(path, string)
    path
  end

  def extract_url(output) do
    output
    |> String.split(~r|[\r\n]+|)
    |> List.first()
    |> String.trim()
    |> String.split(~r|\s+|)
    |> List.last()
    |> String.trim()
  end

  def start(path) do
    GenServer.call(__MODULE__, {:start, path}, 15 * 60 * 1000)
  end

  def stop_all do
    GenServer.call(__MODULE__, :stop_all, 15 * 60 * 1000)
  end
end
