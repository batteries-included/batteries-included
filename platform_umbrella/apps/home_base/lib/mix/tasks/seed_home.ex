defmodule Mix.Tasks.Seed.Home do
  @shortdoc "Seed the home base db with teams and installations"

  @moduledoc """
  Seed the database with the needed
  information to be home base for any bootstrapable installations
  """
  use Mix.Task

  @requirements ["app.config"]

  def run(args) do
    [json_path] = args

    # List the files then for every file in the
    # list if it matches the a different
    # pattern add the filename to a list for that type
    #
    # *team.json is for teams (Currently only one team is emitted)
    # *install.json is for installations
    # Everything else is ignored

    to_import =
      json_path
      |> File.ls!()
      |> Enum.reduce(%{teams: [], installations: []}, fn file_name, acc ->
        full_path = Path.join(json_path, file_name)

        cond do
          String.ends_with?(file_name, "team.json") -> %{acc | teams: [full_path | acc.teams]}
          String.ends_with?(file_name, "install.json") -> %{acc | installations: [full_path | acc.installations]}
          true -> acc
        end
      end)

    :ok = HomeBase.Seed.seed_files(to_import)
  end
end
