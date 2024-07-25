defmodule CommonCore.Installs.Generator do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.Installation
  alias CommonCore.Teams.Team

  typedstruct module: State do
    field :base_team, :map, default: nil
  end

  @state_opts ~w(base_team)a

  def init(opts \\ []) do
    state = struct!(State, opts)
    {:ok, state}
  end

  def start_link(opts \\ []) do
    {opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.put_new_lazy(:base_team, &build_base_team/0)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  def handle_call(:base_team, _from, %State{base_team: base_team} = state) do
    {:reply, base_team, state}
  end

  def handle_call({:build, identifier}, _from, state) do
    {:reply, do_build(identifier, state.base_team.id), state}
  end

  def base_team(target \\ __MODULE__) do
    GenServer.call(target, :base_team)
  end

  def build(target \\ __MODULE__, identifier) do
    GenServer.call(target, {:build, identifier})
  end

  def available_builds do
    [:dev, :local, :elliott, :jason, :maurer, :damian]
  end

  defp build_base_team do
    Team.new!(
      name: "Batteries Included Team",
      op_email: "elliott@batteriesincl.com",
      id: BatteryUUID.autogenerate()
    )
  end

  defp do_build(:dev, team_id) do
    # Our install that we use for dev
    Installation.new!("dev",
      kube_provider: :kind,
      usage: :internal_dev,
      team_id: team_id,
      id: BatteryUUID.autogenerate()
    )
  end

  defp do_build(:local, team_id) do
    # An example of a dev install that customers could use for local testing
    Installation.new!("local",
      kube_provider: :kind,
      usage: :development,
      team_id: team_id,
      id: BatteryUUID.autogenerate()
    )
  end

  defp do_build(:elliott, team_id) do
    # Demo cluster for showing off
    Installation.new!("elliott",
      kube_provider: :aws,
      usage: :development,
      team_id: team_id,
      id: BatteryUUID.autogenerate()
    )
  end

  defp do_build(:jason, team_id) do
    Installation.new!("jason",
      kube_provider: :aws,
      usage: :development,
      team_id: team_id,
      id: BatteryUUID.autogenerate()
    )
  end

  defp do_build(:maurer, team_id) do
    Installation.new!("maurer",
      kube_provider: :aws,
      usage: :development,
      team_id: team_id,
      id: BatteryUUID.autogenerate()
    )
  end

  defp do_build(:damian, team_id) do
    Installation.new!("damian",
      kube_provider: :aws,
      usage: :development,
      team_id: team_id,
      id: BatteryUUID.autogenerate()
    )
  end
end