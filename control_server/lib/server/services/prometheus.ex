defmodule Server.Services.Prometheus do
  @moduledoc """
  Process for syncing the current db status with kubernetes.
  """
  use GenServer
  require Logger
  alias Server.Configs
  alias Server.Configs.RunningSet
  alias Server.FileExt

  @impl true
  def init(state \\ %{status: :starting, client: K8s.Client}) do
    {:ok, state}
  end

  def start_link(state \\ %{status: :starting, client: K8s.Client}, opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)

    case state == [] do
      true ->
        GenServer.start_link(__MODULE__, %{status: :starting, client: K8s.Client}, name: name)

      false ->
        GenServer.start_link(__MODULE__, state, name: name)
    end
  end

  def sync(name \\ __MODULE__, %{} = cluster) do
    GenServer.cast(name, {:sync, cluster})
  end

  def status(name \\ __MODULE__) do
    GenServer.call(name, :status)
  end

  @impl true
  def handle_call(:status, _from, %{status: current_status} = state) do
    {:reply, current_status, state}
  end

  @impl true
  def handle_cast({:sync, cluster}, %{status: current_status} = state) do
    with {:ok, new_status} <- sync_operator(current_status, cluster, state) do
      Logger.info("Sync complete #{inspect(new_status)}")
      {:noreply, %{state | status: new_status}}
    end
  end

  def sync_operator(:starting, _cluster, _state) do
    refresh_db_configs()
    {:ok, :not_running}
  end

  def sync_operator(:not_running = status, _cluster, state) do
    rs = RunningSet.get!()

    with %{"monitoring" => is_running} <- rs.content do
      case is_running do
        true ->
          Logger.info("is_running true. Needing to install")
          install(state)

        false ->
          Logger.info("is_running false")
          {:ok, status}
      end
    end
  end

  def sync_operator(:running, _cluster, _state) do
    rs = RunningSet.get!()

    with %{"monitoring" => is_running} <- rs.content do
      case is_running do
        true ->
          {:ok, :running}

        false ->
          Logger.info("is_running false. This should uninstall")
          {:ok, :not_running}
      end
    end
  end

  def sync_operator(_status, _cluster, _state) do
    {:error, :unknown_status}
  end

  def refresh_db_configs do
    base_path = Application.app_dir(:server, ["priv", "kube-prometheus", "manifests"])

    file_list =
      base_path
      |> FileExt.ls_r()

    file_list
    |> Enum.map(fn p ->
      db_config_path = p |> String.replace_prefix(base_path, "/prometheus/manifests")

      with {:ok, yaml_content} <- YamlElixir.read_from_file(p),
           {:ok, _} <- Configs.upsert(%{path: db_config_path, content: yaml_content}) do
        {:ok, db_config_path}
      end
    end)
  end

  def install(%{client: kube_client}) do
    Logger.info("Syncing the setup files")

    install_in_path(kube_client, "/prometheus/manifests/setup")
    Logger.info("Sync'd the setup files successfully.")
    install_in_path(kube_client, "/prometheus/manifests/")
    Logger.info("Yes!!!")

    {:ok, :running}
  end

  defp install_in_path(kube_client, path) do
    # For each config get it or create it. Then we'll need to
    # check equality and apply. TODO
    #
    # For now this grabs the configs from the db
    # Sorts them by the path
    # then sends them to k8s
    Configs.find_by_prefix(path)
    |> Enum.sort(fn one, two -> one.path < two.path end)
    |> Enum.map(fn rc ->
      Logger.info("Sending get or create for #{rc.path}")
      Server.KubeExt.get_or_create(rc.content, kube_client)
    end)
  end
end
