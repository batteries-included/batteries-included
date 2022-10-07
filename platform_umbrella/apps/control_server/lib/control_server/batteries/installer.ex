defmodule ControlServer.Batteries.Installer do
  alias ControlServer.Batteries.Catalog
  alias ControlServer.Batteries.CatalogBattery
  alias ControlServer.Batteries.SystemBattery
  alias ControlServer.Postgres
  alias ControlServer.Redis
  alias ControlServer.Repo
  alias Ecto.Multi
  alias EventCenter.Database, as: DatabaseEventCenter
  alias ControlServer.Timeline

  require Logger

  def install!(type) do
    with {:ok, result} <- install(type) do
      result
    end
  end

  def install(type) when is_binary(type) do
    atom_type = String.to_existing_atom(type)
    Logger.debug("Install type #{type} atom = #{atom_type}")

    install(atom_type)
  end

  def install(type) when is_atom(type) do
    Logger.info("Begining install of #{type}")
    catalog_battery = Catalog.get(type)
    Logger.debug("Found catalog service", catalog_battery: catalog_battery)
    install(catalog_battery)
  end

  def install(%CatalogBattery{type: type} = catalog_battery) do
    # Get every dep
    # Merge the find_or_create Ecto.Multi of every
    # dependency into one mega dependency multi
    # That we merge into the final result

    deps = get_recursive_deps(catalog_battery)
    Logger.debug("Found #{length(deps)} recursive dependencies", deps: deps)

    Multi.new()
    |> then(fn emtpy ->
      Enum.reduce(deps, emtpy, fn dt, multi ->
        Multi.append(multi, find_or_create_multi(dt))
      end)
    end)
    |> Multi.append(find_or_create_multi(type))
    |> Repo.transaction()
    |> summarize()
    |> broadcast()
  end

  defp get_recursive_deps(%CatalogBattery{dependencies: deps} = _catalog_battery) do
    deps
    |> Enum.concat(
      Enum.flat_map(deps, fn dep_type ->
        dep_type |> Catalog.get() |> get_recursive_deps()
      end)
    )
    |> Enum.uniq()
  end

  defp find_or_create_multi(battery_type) do
    selected_key = "#{battery_type}_selected"
    installed_key = "#{battery_type}_installed"
    post_key = "#{battery_type}_post"
    event_key = "#{battery_type}_event"

    Multi.new()
    |> Multi.run(selected_key, fn repo, _ ->
      # Try getting the already installed battery
      {:ok, repo.get_by(SystemBattery, type: battery_type)}
    end)
    |> Multi.run(installed_key, fn repo, state ->
      # If there wasn't a selected from the
      # db battery then we need to insert it.
      case Map.get(state, selected_key, nil) do
        nil -> repo.insert(changeset(battery_type))
        # Already inserted carry on
        _ -> {:ok, nil}
      end
    end)
    |> Multi.run(post_key, fn repo, so_far ->
      #
      # Right now there's only a post install hook.
      # At some point we might need to
      # include pre-hooks so that init
      #
      #
      # If there was an install then run the post
      case Map.get(so_far, installed_key, nil) do
        nil -> {:ok, nil}
        #
        installed -> post_install(installed, repo)
      end
    end)
    |> Multi.run(event_key, fn repo, so_far ->
      # If there was an install then run the post
      case Map.get(so_far, installed_key, nil) do
        nil ->
          {:ok, nil}

        #
        installed ->
          installed.type
          |> Timeline.battery_install_event()
          |> Timeline.create_timeline_event(repo)
      end
    end)
  end

  defp changeset(battery_type) do
    catalog_battery = Catalog.get(battery_type)

    SystemBattery.changeset(%SystemBattery{}, %{
      type: catalog_battery.type,
      group: catalog_battery.group,
      config: init_config(battery_type)
    })
  end

  defp init_config(_), do: %{}

  defp post_install(%SystemBattery{type: :harbor}, repo) do
    init_pg = KubeRawResources.Harbor.harbor_pg_cluster()
    init_redis = KubeRawResources.Harbor.harbor_redis_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo),
         {:ok, redis} <- Redis.create_failover_cluster(init_redis, repo) do
      {:ok, harbor_postgres: postgres_db, harbor_redis: redis}
    end
  end

  defp post_install(%SystemBattery{type: :database_internal}, repo) do
    init_pg = KubeRawResources.Battery.control_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, internal_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: :gitea}, repo) do
    init_pg = KubeRawResources.Gitea.gitea_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, gitea_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: :ory_hydra}, repo) do
    init_pg = KubeRawResources.OryHydra.hydra_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, hydra_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: _}, _repo), do: {:ok, nil}

  defp summarize({:ok, multi_result}) do
    {:ok,
     multi_result
     |> Enum.filter(fn {_k, v} -> v != nil end)
     |> Enum.map(fn {key, value} ->
       cleaned_key = clean_key(key)

       {result_type(key), cleaned_key, value}
     end)
     |> Enum.reduce(
       %{installed: %{}, selected: %{}, post: %{}, timeline_event: %{}},
       fn {result_type, key, value}, res ->
         put_in(res, [result_type, key], value)
       end
     )}
  end

  defp summarize(error_result), do: error_result

  defp result_type(key) do
    cond do
      String.ends_with?(key, "_installed") -> :installed
      String.ends_with?(key, "_selected") -> :selected
      String.ends_with?(key, "_post") -> :post
      String.ends_with?(key, "_event") -> :timeline_event
      true -> :unknown
    end
  end

  defp clean_key(key) do
    key
    |> String.replace("_installed", "")
    |> String.replace("_selected", "")
    |> String.replace("_post", "")
    |> String.replace("_event", "")
    |> String.to_existing_atom()
  end

  defp broadcast({:ok, install_result} = result) do
    :ok = DatabaseEventCenter.broadcast(:system_battery, :multi, install_result)
    result
  end

  defp broadcast(result), do: result
end
