defmodule Verify.KindInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ApiVersionKind
  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.StateSummary.Namespaces
  alias Verify.PathHelper

  require Logger

  typedstruct module: State do
    field :bi_binary, :string
    field :root_path, :string
    field :started, :map, default: %{}
  end

  @state_opts ~w(bi_binary root_path)a

  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.put_new_lazy(:root_path, &PathHelper.tmp_dir!/0)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(args) do
    state = struct!(State, args)

    Logger.info("Starting KindInstallWorker")

    {:ok, state}
  end

  # determine bi_binary if necessary
  def handle_call({:start, identifier}, _from, %{bi_binary: nil} = state) do
    do_start(identifier, %{state | bi_binary: PathHelper.find_bi()})
  end

  def handle_call({:start, identifier}, _from, state) do
    do_start(identifier, state)
  end

  # determine bi_binary if necessary
  def handle_call(:stop_all, _from, %{bi_binary: nil} = state) do
    do_stop_all(%{state | bi_binary: PathHelper.find_bi()})
  end

  def handle_call(:stop_all, _from, state) do
    do_stop_all(state)
  end

  def handle_call({:rage, {mod, name}}, _from, %{bi_binary: nil} = state) do
    do_rage(mod, name, %{state | bi_binary: PathHelper.find_bi()})
  end

  def handle_call({:rage, {mod, output}}, _from, state) do
    do_rage(mod, output, state)
  end

  defp do_start({mod, identifier}, state) do
    {spec, path} = build_install_spec(identifier, state)
    Logger.debug("Starting with #{path}")
    env = [{"BI_IMAGE_TAR", System.get_env("BI_IMAGE_TAR", "")}]

    with {_output, 0} <-
           System.cmd(state.bi_binary, ["start", path], env: env),
         {kube_config_path, 0} <-
           System.cmd(state.bi_binary, ["debug", "kube-config-path", path]),
         {:ok, url} <- get_url(spec, kube_config_path) do
      Logger.debug("Kind install started from #{path}")
      Logger.debug("Kubeconfig found at #{kube_config_path}")

      {:reply, {:ok, url, kube_config_path}, %{state | started: Map.put(state.started, mod, path)}}
    else
      error ->
        Logger.warning("Unable to start Kind install from #{path}")
        {:reply, error, state}
    end
  end

  defp do_stop_all(%{started: started} = state) do
    Enum.each(started, fn {_, path} ->
      :ok = do_stop(state.bi_binary, path)
    end)

    {:reply, :ok, %{state | started: %{}}}
  end

  defp do_stop(bi, path) do
    spec = path |> File.read!() |> Jason.decode!()
    slug = Map.fetch!(spec, "slug")

    Logger.info("Stopping Kind install with path = #{path} slug #{slug}")

    {_, 0} = System.cmd(bi, ["stop", slug])

    # Remove the file after stopping the install
    _ = File.rm_rf(path)
    :ok
  end

  defp do_rage(mod, output, %{bi_binary: bi, started: started} = state) do
    {_, path} = Enum.find(started, fn {module, _} -> module == mod end)

    case System.cmd(bi, ["rage", path, "-o=#{output}"], stderr_to_stdout: true) do
      {output, 0} ->
        Logger.debug("Rage ran: #{inspect(output)}")
        {:reply, :ok, state}

      response ->
        Logger.error("Rage failed for: #{inspect(response)}")
        {:reply, response, state}
    end
  end

  def build_install_spec(identifier, %{root_path: root_dir} = _state) do
    install = CommonCore.Installs.Generator.build(Verify.Installs.Generator, identifier)
    spec = CommonCore.InstallSpec.new!(install)
    id = BatteryUUID.autogenerate()
    path = Path.join(root_dir, "#{id}_#{install.slug}.spec.json")
    string = Jason.encode_to_iodata!(spec, pretty: true, escape: :javascript_safe)
    :ok = File.write!(path, string)
    {spec, path}
  end

  def get_url(%{target_summary: summary} = _spec, kube_config_path) do
    # don't use the connection pool
    {:ok, conn} = K8s.Conn.from_file(kube_config_path, insecure_skip_tls_verify: true)

    {api_version, kind} = ApiVersionKind.from_resource_type!(:config_map)
    core_namespace = Namespaces.core_namespace(summary)
    op = K8s.Client.get(api_version, kind, name: "access-info", namespace: core_namespace)

    case K8s.Client.run(conn, op) do
      {:ok, %{"data" => %{"hostname" => hostname, "ssl" => ssl}}} ->
        {:ok, "#{if ssl == "true", do: "https", else: "http"}://#{hostname}"}

      error ->
        error
    end
  end

  def start(mod, identifier) do
    GenServer.call(__MODULE__, {:start, {mod, identifier}}, 15 * 60 * 1000)
  end

  def rage(mod, output) do
    GenServer.call(__MODULE__, {:rage, {mod, output}}, 15 * 60 * 1000)
  end

  def stop_all do
    GenServer.call(__MODULE__, :stop_all, 15 * 60 * 1000)
  end
end
