defmodule Mix.Tasks.Seed.Control do
  @shortdoc "Seed the control server db with an install"

  @moduledoc """
  Seed the database with the needed
  information to boot up a new installation.
  """
  use Mix.Task

  @requirements ["app.config"]

  def run(args) do
    [json_summary_path] = args

    ControlServer.Release.seed(json_summary_path)
  end
end
