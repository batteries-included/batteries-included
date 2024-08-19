defmodule Mix.Tasks.Gen.Static.Installations do
  @shortdoc "Just enough to get a dev cluster up and running."

  @moduledoc "Create the json for static installations that can be used during dev cluster bring up."
  use Mix.Task

  alias CommonCore.Installs.Generator
  alias CommonCore.Installs.HomeBaseInitData
  alias CommonCore.InstallSpec

  def run(args) do
    [directory] = args

    File.mkdir_p!(directory)

    {:ok, pid} = Generator.start_link()

    installs = Enum.map(Generator.available_builds(), fn identifier -> Generator.build(pid, identifier) end)

    teams = [Generator.base_team()]
    home_base_init_data = %HomeBaseInitData{installs: installs, teams: teams}

    installs
    |> Enum.map(fn install -> {Path.join(directory, "#{install.slug}.install.json"), install} end)
    |> Enum.concat(Enum.map(teams, fn team -> {Path.join(directory, "team.json"), team} end))
    |> Enum.each(fn {path, contents} -> write!(path, contents) end)

    installs
    |> Enum.map(fn install ->
      {
        Path.join(directory, "#{install.slug}.spec.json"),
        InstallSpec.new!(install, home_base_init_data: home_base_init_data)
      }
    end)
    |> Enum.each(fn {path, contents} -> write!(path, contents) end)
  end

  def write!(path, data) do
    string = Jason.encode_to_iodata!(data, pretty: true, escape: :javascript_safe)
    File.write!(path, string)
  end
end
