defmodule ControlServer.Batteries.Installer do
  alias KubeExt.Defaults.Catalog
  alias KubeExt.Defaults.CatalogBattery
  alias KubeExt.RequiredDatabases

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

  def install(%CatalogBattery{} = catalog_battery) do
    # Get every dep
    # Merge the find_or_create Ecto.Multi of every
    # dependency into one mega dependency multi
    # That we merge into the final result

    all_batteries = get_recursive(catalog_battery)
    Logger.debug("Found #{length(all_batteries)} recursive dependencies", deps: all_batteries)
    do_install(all_batteries)
  end

  def install_all(batteries) do
    # get the catalog batteries for everything
    # Then make sure that we have all the dependencies.
    # We should since install_all should be used with a snapshot.
    # Then make the whole thing unique.
    catalog_batteries =
      batteries
      |> Enum.map(&Catalog.get(&1.type))
      |> Enum.flat_map(&get_recursive/1)
      |> Enum.uniq()

    overrides = batteries |> Enum.map(&{&1.type, &1}) |> Map.new()

    do_install(catalog_batteries, overrides)
  end

  defp do_install(catalog_batteries, overrides \\ %{}) do
    catalog_batteries
    |> Enum.map(fn battery ->
      override = Map.get(overrides, battery.type, %{})
      find_or_create_multi(battery, override)
    end)
    |> Enum.reduce(Multi.new(), fn battery_type_multi, multi ->
      Multi.append(multi, battery_type_multi)
    end)
    |> Repo.transaction()
    |> summarize()
    |> broadcast()
  end

  defp get_recursive(%CatalogBattery{dependencies: deps} = catalog_battery) do
    (deps || [])
    |> Enum.flat_map(fn dep_type ->
      dep_type |> Catalog.get() |> get_recursive()
    end)
    |> Enum.concat([catalog_battery])
    |> Enum.uniq()
  end

  defp find_or_create_multi(
         %CatalogBattery{type: battery_type} = catalog_battery,
         %{} = value_overrides
       ) do
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
        nil -> repo.insert(changeset(catalog_battery, value_overrides))
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

  defp changeset(catalog_battery, override) do
    SystemBattery.changeset(
      %SystemBattery{},
      clean_merge(catalog_battery, override)
    )
  end

  defp to_map(val) when is_struct(val), do: Map.from_struct(val)
  defp to_map(val) when is_map(val), do: val
  defp clean_merge(m1, m2), do: Map.merge(to_map(m1), to_map(m2))

  defp post_install(%SystemBattery{type: :harbor}, repo) do
    init_pg = RequiredDatabases.Harbor.harbor_pg_cluster()
    init_redis = RequiredDatabases.Harbor.harbor_redis_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo),
         {:ok, redis} <- Redis.create_failover_cluster(init_redis, repo) do
      {:ok, harbor_postgres: postgres_db, harbor_redis: redis}
    end
  end

  defp post_install(%SystemBattery{type: :database_internal}, repo) do
    init_pg = RequiredDatabases.Control.control_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, internal_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: :gitea}, repo) do
    init_pg = RequiredDatabases.Gitea.gitea_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, gitea_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: :ory_hydra}, repo) do
    init_pg = RequiredDatabases.OryHydra.hydra_cluster()

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
