defmodule ControlServer.Batteries.Installer do
  @moduledoc false
  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.SystemBattery
  alias CommonCore.Defaults
  alias ControlServer.Postgres
  alias ControlServer.Repo
  alias Ecto.Multi
  alias EventCenter.Database, as: DatabaseEventCenter

  require Logger

  def install!(type, update_target \\ nil) do
    with {:ok, result} <- install(type, update_target) do
      result
    end
  end

  def install(type, update_target \\ nil)

  def install(type, update_target) when is_binary(type), do: install(String.to_existing_atom(type), update_target)

  def install(type, update_target) when is_atom(type) do
    Logger.info("Begining install of #{type}")

    type
    |> Catalog.get()
    |> install(update_target)
  end

  def install(%CatalogBattery{} = catalog_battery, update_target) do
    catalog_battery
    |> CatalogBattery.to_fresh_args()
    |> List.wrap()
    |> install_all(update_target)
  end

  def install(%SystemBattery{} = system_battery, update_target), do: install_all([system_battery], update_target)

  def install_all(batteries, update_target \\ nil) do
    update_progress(update_target, :starting)
    # For every battery that's passed in get the dependencies
    # as catalog batteries (`CommonCore.Batteries.CatalogBattery`).
    #
    # Then make the whole list unique
    #
    # Then convert all those to system batteries giving preference to the passed
    # in batteries and their possibly customized configs.
    #
    # Give that list to the `do_install method` which actually does the
    # combined find or create multi transaction for all batteries

    start_arg_map =
      Map.new(batteries, fn sb -> {sb.type, SystemBattery.to_fresh_args(sb)} end)

    batteries
    |> Enum.map(&Catalog.get(&1.type))
    |> Enum.flat_map(&Catalog.get_recursive/1)
    |> Enum.uniq_by(& &1.type)
    |> Enum.reduce(
      start_arg_map,
      fn catalog_battery, battery_map ->
        Map.put_new_lazy(battery_map, catalog_battery.type, fn ->
          CatalogBattery.to_fresh_args(catalog_battery)
        end)
      end
    )
    |> Map.values()
    |> then(fn battery_arg_list ->
      update_progress(update_target, :args_ready)
      battery_arg_list
    end)
    |> do_install(update_target)
  end

  defp do_install(battery_arg_list, update_target) do
    battery_arg_list
    |> Enum.map(fn arg ->
      find_or_create_multi(arg)
    end)
    |> Enum.reduce(Multi.new(), fn battery_type_multi, multi ->
      Multi.append(multi, battery_type_multi)
    end)
    |> Repo.transaction()
    |> summarize()
    |> broadcast(update_target)
  end

  defp find_or_create_multi(%{type: battery_type} = battery_args) do
    selected_key = "#{battery_type}_selected"
    installed_key = "#{battery_type}_installed"
    post_key = "#{battery_type}_post"

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

  defp post_install(%SystemBattery{type: :battery_core, config: %{default_size: default_size}}, repo) do
    init_pg = Defaults.ControlDB.control_cluster(default_size || :tiny)

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, internal_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: :forgejo}, repo) do
    init_pg = Defaults.ForgejoDB.forgejo_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, forgejo_postgres: postgres_db}
    end
  end

  defp post_install(%SystemBattery{type: :keycloak}, repo) do
    init_pg = Defaults.KeycloakDB.pg_cluster()

    with {:ok, postgres_db} <- Postgres.find_or_create(init_pg, repo) do
      {:ok, sso_db: postgres_db}
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

  defp update_progress(target, msg)
  defp update_progress(nil = _target, _msg), do: :ok

  defp update_progress(update_target, msg) do
    send(update_target, {:async_installer, msg})
  end

  defp broadcast({:ok, install_result} = result, update_target) do
    :ok = DatabaseEventCenter.broadcast(:system_battery, :multi, install_result)
    update_progress(update_target, {:install_complete, install_result})
    result
  end

  defp broadcast(failed_result, update_target) do
    update_progress(update_target, {:install_failed, failed_result})
    failed_result
  end
end
