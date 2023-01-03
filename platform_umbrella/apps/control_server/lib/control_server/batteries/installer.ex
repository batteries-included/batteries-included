defmodule ControlServer.Batteries.Installer do
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Defaults

  alias ControlServer.Postgres
  alias ControlServer.Redis
  alias ControlServer.Repo
  alias ControlServer.Timeline

  alias Ecto.Multi
  alias EventCenter.Database, as: DatabaseEventCenter

  require Logger

  def install!(type) do
    with {:ok, result} <- install(type) do
      result
    end
  end

  def install(type) when is_binary(type) do
    atom_type = String.to_existing_atom(type)
    install(atom_type)
  end

  def install(type) when is_atom(type) do
    Logger.info("Begining install of #{type}")

    type
    |> Catalog.get()
    |> install()
  end

  def install(%CatalogBattery{} = catalog_battery) do
    catalog_battery
    |> CatalogBattery.to_fresh_args()
    |> List.wrap()
    |> install_all()
  end

  def install(%SystemBattery{} = system_battery), do: install_all([system_battery])

  def install_all(batteries) do
    # For every battery that's there get the dependencies as catalog batteries.
    # Then make the whole list unique
    # Then convert all those to system batteries giving preference to the passed in batteries and their possibly customized configs.
    # Give that list to the `do_install method`
    batteries
    |> Enum.map(&Catalog.get(&1.type))
    |> Enum.flat_map(&Catalog.get_recursive/1)
    |> Enum.uniq_by(& &1.type)
    |> Enum.reduce(
      batteries |> Enum.map(&{&1.type, &1}) |> Map.new(),
      fn catalog_battery, battery_map ->
        Map.put_new_lazy(battery_map, catalog_battery.type, fn ->
          CatalogBattery.to_fresh_args(catalog_battery)
        end)
      end
    )
    |> Map.values()
    |> do_install()
  end

  defp do_install(battery_arg_list) do
    battery_arg_list
    |> Enum.map(fn arg ->
      find_or_create_multi(arg)
    end)
    |> Enum.reduce(Multi.new(), fn battery_type_multi, multi ->
      Multi.append(multi, battery_type_multi)
    end)
    |> Repo.transaction()
    |> summarize()
    |> broadcast()
  end

  defp find_or_create_multi(%{type: battery_type} = battery_args) do
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
        nil ->
          repo.insert(changeset(%SystemBattery{}, battery_args))

        # Already inserted carry on
        _ ->
          {:ok, nil}
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
    init_pg = Defaults.HarborDB.harbor_pg_cluster()
    init_redis = Defaults.HarborDB.harbor_redis_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo),
         {:ok, redis} <- Redis.create_failover_cluster(init_redis, repo) do
      {:ok, harbor_postgres: postgres_db, harbor_redis: redis}
    end
  end

  defp post_install(%SystemBattery{type: :database_internal}, repo) do
    init_pg = Defaults.ControlDB.control_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, internal_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: :gitea}, repo) do
    init_pg = Defaults.GiteaDB.gitea_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, gitea_postgres: postgres_db}
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
