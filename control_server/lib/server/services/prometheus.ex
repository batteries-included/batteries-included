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
    # Get the name so that we can start this with different names.
    name = Keyword.get(opts, :name, __MODULE__)

    # If there's no default then use :starting and K8s.Client as the default state.
    # Start up the GenServer
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
    # Try and sync the operator. This should start up prometheus cluster
    with {:ok, new_status} <- sync_operator(current_status, cluster, state) do
      Logger.info("Prometheus Sync complete status: #{current_status} -> #{inspect(new_status)}")
      {:noreply, %{state | status: new_status}}
    end
  end

  def sync_operator(:starting, _cluster, _state) do
    # If we don't know for sure the prometheus operator has
    # been synced. Then refresh the configs from priv into the
    # database.
    _refreshed = refresh_db_configs() |> Enum.map(fn {_status, path} -> path end)
    {:ok, :not_running}
  end

  def sync_operator(:not_running = status, _cluster, state) do
    # Everything should be in the db. So check the configs to see
    # should this be running at all?
    with %{"monitoring" => is_running} <- RunningSet.get!().content do
      case is_running do
        true ->
          Logger.info("is_running true. Needing to install")
          install(state)

        _ ->
          Logger.info("is_running false")
          {:ok, status}
      end
    end
  end

  def sync_operator(:running, _cluster, _state) do
    with %{"monitoring" => is_running} <- RunningSet.get!().content do
      case is_running do
        true ->
          # TODO: Check status here.
          {:ok, :running}

        _ ->
          # TODO: Uninstall monitoring.
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

    # All the kube-prometheus operator files are in priv
    # recursively list all the them. Then try and upsert them
    base_path
    |> FileExt.ls_r()
    |> Enum.map(fn p ->
      # the path in config db should be usable regardless
      # of where in priv this is all located.
      db_config_path = p |> String.replace_prefix(base_path, "/prometheus/manifests")

      # Read yaml and shove that into the contents field use the
      # computed path above and then upsert
      with {:ok, yaml_content} <- YamlElixir.read_from_file(p),
           {:ok, _} <- Configs.upsert(%{path: db_config_path, content: yaml_content}) do
        # Return the path that's for sure present now. We don't know the contents.
        {:ok, db_config_path}
      end
    end)
  end

  def install(%{client: kube_client}) do
    Logger.info("Syncing the setup files")

    install_in_path(kube_client, "/prometheus/manifests/setup")
    Logger.info("Sync'd the setup files successfully.")
    install_in_path(kube_client, "/prometheus/manifests/")

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
