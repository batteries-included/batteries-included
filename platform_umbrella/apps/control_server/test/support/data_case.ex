defmodule ControlServer.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ControlServer.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      import ControlServer.DataCase
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias ControlServer.Repo
    end
  end

  setup tags do
    ControlServer.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(ControlServer.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def assert_config_map_good(config_map) do
    Enum.each(config_map, fn {_path, resource} ->
      case resource do
        resource_list when is_list(resource_list) ->
          Enum.map(resource_list, &assert_resource_good/1)

        _ ->
          assert_resource_good(resource)
      end
    end)
  end

  defp assert_resource_good(single_resource) do
    operation = K8s.Client.create(single_resource)
    assert Map.get(operation.data, "metadata") == Map.get(single_resource, "metadata")
  end

  @typep pagination_fixture_fn :: (%{name: String.t()} -> map())
  @typep pagination_list_fn :: (map() | Flop.t() -> {:ok, {[any()], Flop.Meta.t()}} | {:error, Flop.Meta.t()})
  @typep pagination_option :: {:count, pos_integer()}
  @typep pagination_options :: [pagination_option()]

  @doc """
  Run DB list tests that excercise Flop pagination
  The fixture fn should accept a map parameter that is able to change the name of the entity
  The list fn should accept Flop params e.g. `ControlServer.Postgres.list_clusters/1`
  """
  @spec pagination_test(pagination_fixture_fn(), pagination_list_fn(), pagination_options()) :: any()
  def pagination_test(fixture_fn, list_fn, opts \\ []) do
    count = Keyword.get(opts, :count, 10)
    prefix = build_prefix(depth: 3)

    params = %{
      order_by: [:id],
      filters: [%{field: :name, op: :ilike, value: "#{prefix}-"}],
      page_size: 1,
      page: nil
    }

    entities = Enum.map(1..count, fn i -> fixture_fn.(%{name: "#{prefix}-#{i}"}) end)

    # page through one page / entity at a time
    assert [] = Enum.reduce(1..count, entities, build_pagination_assertions(list_fn, params, count))

    # all entities are found on a single page if page_size >= count
    assert {:ok, {found, meta}} = list_fn.(%{params | page: 1, page_size: count})
    assert Enum.all?(entities, fn e -> Enum.any?(found, &(&1.id == e.id && &1.name == e.name)) end)
    assert meta.has_next_page? == false
  end

  defp build_pagination_assertions(list_fn, params, count) do
    fn i, entities ->
      # get the ith page
      assert {:ok, {[ith], meta}} = list_fn.(%{params | page: i})

      case i do
        1 ->
          # first page doesn't have prev page
          assert {false, true} = {meta.has_previous_page?, meta.has_next_page?}

        ^count ->
          # last page doesn't have next page
          assert {true, false} = {meta.has_previous_page?, meta.has_next_page?}

        _ ->
          # every other page should have prev and next
          assert {true, true} = {meta.has_previous_page?, meta.has_next_page?}
      end

      # ensure that the result is in the list of created entities
      assert Enum.any?(entities, &(&1.id == ith.id))

      # remove the found element. it shouldn't be returned from the DB again
      Enum.reject(entities, &(&1.id == ith.id))
    end
  end

  @typep build_prefix_option :: {:depth, pos_integer()}
  @typep build_prefix_options :: [build_prefix_option()]

  @doc """
  Generate a prefix (or suffix) based on the caller's module name.
  The depth option may be useful to increase depending on the call stack
  """
  @spec build_prefix(build_prefix_options()) :: String.t()
  def build_prefix(opts \\ []) do
    self()
    |> Process.info(:current_stacktrace)
    |> elem(1)
    |> Enum.fetch!(Keyword.get(opts, :depth, 2))
    |> elem(0)
    |> Module.split()
    |> Enum.map_join("-", &(&1 |> Macro.underscore() |> String.downcase() |> String.replace("_", "-")))
  end
end
