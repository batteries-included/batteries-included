defmodule ControlServerWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ControlServerWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      use ControlServerWeb, :verified_routes

      import ControlServerWeb.ConnCase
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import Plug.Conn

      # The default endpoint for testing
      @endpoint ControlServerWeb.Endpoint
    end
  end

  setup tags do
    :ok = Sandbox.checkout(ControlServer.Repo)

    if !tags[:async] do
      Sandbox.mode(ControlServer.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Checks if an element inside a LiveView or HTML block contains a class.
  """
  def has_class?(%Phoenix.LiveViewTest.View{} = view, selector, class) do
    view
    |> Phoenix.LiveViewTest.render()
    |> has_class?(selector, class)
  end

  def has_class?(html, selector, class) do
    html
    |> Floki.parse_document!()
    |> Floki.attribute(selector, "class")
    |> Enum.map(&String.split/1)
    |> Enum.any?(fn x -> Enum.any?(x, &(&1 == class)) end)
  end
end
