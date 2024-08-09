defmodule Mix.Tasks.Gen.Static.Installations do
  @shortdoc "Just enough to get a dev cluster up and running."

  @moduledoc "Create the json for static installations that can be used during dev cluster bring up."
  use Mix.Task

  alias CommonCore.Installs.Generator
  alias CommonCore.InstallSpec

  def run(args) do
    [directory] = args

    File.mkdir_p!(directory)

    {:ok, pid} = Generator.start_link()

    Generator.available_builds()
    |> Enum.map(fn identifier ->
      Generator.build(pid, identifier)
    end)
    |> Enum.flat_map(fn install ->
      [
        {Path.join(directory, "#{install.slug}.spec.json"), InstallSpec.new!(install)},
        {Path.join(directory, "#{install.slug}.install.json"), install}
      ]
    end)
    |> Enum.concat([
      {Path.join(directory, "team.json"), Generator.base_team()}
    ])
    |> Enum.each(fn {path, contents} ->
      write!(path, contents)
    end)
  end

  def write!(path, data) do
    string = Jason.encode_to_iodata!(data, pretty: true, escape: :javascript_safe)
    File.write!(path, string)
  end
end
