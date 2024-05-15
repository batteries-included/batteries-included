defmodule Mix.Tasks.Gen.Static.Installations do
  @shortdoc "Just enough to get a dev cluster up and running."

  @moduledoc "Create the json for static installations that can be used during dev cluster bring up."
  use Mix.Task

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.Installation
  alias CommonCore.InstallSpec
  alias CommonCore.Teams.Team

  def run(args) do
    [directory] = args

    File.mkdir_p!(directory)

    team =
      Team.new!(
        name: "Batteries Included Team",
        op_email: "elliott@batteriesincl.com",
        id: BatteryUUID.autogenerate()
      )

    [
      # Our install that we use for dev
      Installation.new!("dev",
        kube_provider: :kind,
        usage: :internal_dev,
        team_id: team.id,
        id: BatteryUUID.autogenerate()
      ),

      # An example of a dev install that customers could use for local testing
      Installation.new!("local",
        kube_provider: :kind,
        usage: :development,
        team_id: team.id,
        id: BatteryUUID.autogenerate()
      ),

      # Demo cluster for showing off
      Installation.new!("elliott",
        kube_provider: :aws,
        usage: :development,
        team_id: team.id,
        id: BatteryUUID.autogenerate()
      ),
      # JasonT is currently working on bootstrapping the control server
      # so his aws cluster gets the control server installed in the kube cluster
      Installation.new!("jason",
        kube_provider: :aws,
        usage: :development,
        team_id: team.id,
        id: BatteryUUID.autogenerate()
      ),
      Installation.new!("damian",
        kube_provider: :aws,
        usage: :internal_dev,
        team_id: team.id,
        id: BatteryUUID.autogenerate()
      ),

      # Internal Integration tests
      Installation.new!("integration-test",
        kube_provider: :kind,
        usage: :internal_int_test,
        team_id: team.id,
        id: BatteryUUID.autogenerate()
      )
    ]
    |> Enum.flat_map(fn install ->
      [
        {Path.join(directory, "#{install.slug}.spec.json"), InstallSpec.new!(install)},
        {Path.join(directory, "#{install.slug}.install.json"), install}
      ]
    end)
    |> Enum.concat([
      {Path.join(directory, "team.json"), team}
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
