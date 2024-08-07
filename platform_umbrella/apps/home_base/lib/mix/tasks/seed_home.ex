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

    HomeBase.Release.seed(json_path)
  end
end
