defmodule Mix.Tasks.HomeBase.MakeAdmin do
  @shortdoc "Add a user to the internal Batteries Included teams"
  @moduledoc """
  Adds a user by their email to all the internal Batteries Included teams as an admin.
  """

  use Mix.Task

  @start_apps [:postgrex, :ecto, :ecto_sql, :home_base]
  @shutdown_adnormal {:shutdown, 1}
  @shutdown_normal {:shutdown, 0}

  # Run is always going to exit.
  # That's expected
  @dialyzer {:nowarn_function, run: 1}

  def run(args) do
    case args do
      [email] ->
        {:ok, _} = Application.ensure_all_started(@start_apps)
        HomeBase.Release.make_admin!(email)
        exit(@shutdown_normal)

      _ ->
        Mix.shell().error("Error: Please pass a user email as the first argument")
        exit(@shutdown_adnormal)
    end
  end
end
