defmodule Mix.Tasks.Seed.Control do
  @moduledoc """
  Seed the database with the needed
  information to boot up a new installation.
  """
  @shortdoc "Seed the control server db with an install"

  use Mix.Task

  def run(args) do
    [json_install_path] = args

    ControlServer.Release.seed(json_install_path)
  end
end
