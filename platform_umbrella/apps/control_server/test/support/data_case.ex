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
end
