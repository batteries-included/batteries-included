defmodule Verify.KindInstallWorker do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ApiVersionKind
  alias CommonCore.Ecto.BatteryUUID
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
    Process.flag(:trap_exit, true)

    {:ok, state}
  end

  def terminate(_reason, %{bi_binary: nil} = _state), do: :ok
  def terminate(_reason, state), do: do_stop_all(state)

  def handle_call({:start, {:cmd, _cmd, slug, _host} = args}, from, state) do
    # update state and return continuation so we can catch exit on timeout and rage
    {:noreply, %{state | started: Map.put(state.started, slug, "")}, {:continue, {args, from}}}
  end

  def handle_call({:start, {:spec, _identifier, slug} = args}, from, state) do
    # update state and return continuation so we can catch exit on timeout and rage
    {:noreply, %{state | started: Map.put(state.started, slug, "")}, {:continue, {args, from}}}
  end

  def handle_call(:stop_all, _from, state) do
    do_stop_all(state)
  end

  def handle_call({:rage, output}, _from, state) do
    do_rage(output, state)
  end

  def handle_continue({args, from}, state) do
    do_start(args, from, state)
  end

  def handle_info({:EXIT, _, _}, state), do: {:noreply, state}

  def handle_info(msg, state) do
    Logger.error("Caught unhandled message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp do_start({:cmd, cmd, _slug, host}, from, state) do
    Logger.debug("Running #{cmd}")

    env = [
      {"BI_ADDITIONAL_HOSTS", host},
      {"BI_NVIDIA_AUTO_DISCOVERY", "false"},
      {"BI_ALLOW_TEST_KEYS", "true"},
      {"BI_OVERRIDE_LOC", state.bi_binary},
      {"BI_IMAGE_TAR", System.get_env("BI_IMAGE_TAR", "")},
      {"VERSION_OVERRIDE", System.get_env("VERSION_OVERRIDE", "")}
    ]

    # these clusters use the gateway.
    # we need to figure out how to connect to it programatically first
    # so for now just start it
    {_output, 0} = System.shell(cmd, env: env, stderr_to_stdout: true)
    GenServer.reply(from, {:ok})
    {:noreply, state}
  end

  defp do_start({:spec, identifier, slug}, from, state) do
    {_spec, path} = build_install_spec(identifier, slug, state)
    Logger.debug("Starting with #{path}")

    env = [
      {"BI_IMAGE_TAR", System.get_env("BI_IMAGE_TAR", "")},
      {"BI_NVIDIA_AUTO_DISCOVERY", "false"},
      {"BI_ALLOW_TEST_KEYS", "true"}
    ]

    with {_output, 0} <- System.cmd(state.bi_binary, ["start", path], env: env),
         {kube_config_path, 0} <- System.cmd(state.bi_binary, ["debug", "kube-config-path", slug]),
         {:ok, url} <- get_url(kube_config_path) do
      Logger.debug("Kind install started for #{slug}")
      Logger.debug("Kubeconfig found at #{kube_config_path}")

      GenServer.reply(from, {:ok, url, kube_config_path})
      {:noreply, %{state | started: Map.put(state.started, slug, path)}}
    else
      error ->
        Logger.warning("Unable to start Kind install from #{path}")
        GenServer.reply(from, {:error, error})
        {:noreply, state}
    end
  end

  defp do_stop_all(%{started: started, bi_binary: bi} = state) do
    Enum.each(started, fn {slug, path} ->
      :ok = do_stop(slug, path, bi)
    end)

    {:reply, :ok, %{state | started: %{}}}
  end

  defp do_stop(slug, path, bi) do
    Logger.info("Stopping Kind install with path: #{path}, slug: #{slug}, bi: #{bi}")

    {_, 0} = System.cmd(bi, ["stop", slug])

    # Remove the file after stopping the install
    if path != "" do
      _ = File.rm_rf(path)
    end

    :ok
  end

  defp do_rage(output, %{bi_binary: bi, started: started} = state) do
    time = :second |> :erlang.system_time() |> to_string()

    results =
      Enum.map(started, fn {slug, _path} ->
        full_output = Path.join(output, "#{time}_#{slug}.json")

        case System.cmd(bi, ["rage", slug, "-o=#{full_output}"], stderr_to_stdout: true) do
          {stdout, 0} ->
            Logger.debug("Rage ran: #{inspect(stdout)}")
            :ok

          response ->
            Logger.error("Rage failed for: #{inspect(response)}")
            response
        end
      end)

    {:reply, results, state}
  end

  def build_install_spec(identifier, slug, %{root_path: root_dir} = _state) do
    install =
      Verify.Installs.Generator
      |> CommonCore.Installs.Generator.build(identifier)
      |> Map.put(:slug, slug)

    spec = CommonCore.InstallSpec.new!(install)
    id = BatteryUUID.autogenerate()
    path = Path.join(root_dir, "#{id}_#{slug}.spec.json")
    string = Jason.encode_to_iodata!(spec, pretty: true, escape: :javascript_safe)
    :ok = File.write!(path, string)
    {spec, path}
  end

  def get_url(kube_config_path) do
    # don't use the connection pool
    {:ok, conn} = K8s.Conn.from_file(kube_config_path, insecure_skip_tls_verify: true)

    {api_version, kind} = ApiVersionKind.from_resource_type!(:config_map)
    op = K8s.Client.get(api_version, kind, name: "access-info", namespace: "battery-core")

    case K8s.Client.run(conn, op) do
      {:ok, %{"data" => %{"hostname" => hostname, "ssl" => ssl}}} ->
        {:ok, "#{if ssl == "true", do: "https", else: "http"}://#{hostname}"}

      error ->
        error
    end
  end

  def start_from_command(target, start_cmd, slug, host) do
    GenServer.call(target, {:start, {:cmd, start_cmd, slug, host}}, 15 * 60 * 1000)
  end

  def start_from_spec(target, identifier, slug) do
    GenServer.call(target, {:start, {:spec, identifier, slug}}, 15 * 60 * 1000)
  end

  def rage(target, output) do
    GenServer.call(target, {:rage, output}, 15 * 60 * 1000)
  end

  def stop_all(target) do
    GenServer.call(target, :stop_all, 15 * 60 * 1000)
  end
end
