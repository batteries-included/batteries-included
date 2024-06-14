defmodule HomeBase.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: HomeBase.Repo

  alias CommonCore.Accounts.User
  alias CommonCore.Installation
  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole
  alias HomeBase.Accounts
  alias HomeBase.ET.StoredHostReport
  alias HomeBase.ET.StoredUsageReport

  defdelegate usage_report_factory(), to: CommonCore.Factory
  defdelegate host_report_factory(), to: CommonCore.Factory

  def stored_usage_report_factory do
    %StoredUsageReport{report: build(:usage_report), installation: build(:installation)}
  end

  def stored_host_report_factory do
    %StoredHostReport{report: build(:host_report), installation: build(:installation)}
  end

  def user_factory do
    %User{
      email: sequence("user-") <> "@example.com",
      password: "qwer1234",
      hashed_password: "$2b$12$Cx0OPVZ5xwCuHVvQdH1TouyCov581bTNPBQNaJMSJehRH8MrkZgGu"
    }
  end

  def team_factory do
    name = sequence("team-")

    %Team{
      name: name,
      op_email: "op@#{name}.com"
    }
  end

  def team_role_factory do
    %TeamRole{
      is_admin: false
    }
  end

  def installation_factory do
    %Installation{
      slug: sequence("installation-"),
      usage: sequence(:usage, [:kitchen_sink, :development, :production]),
      kube_provider: sequence(:kube_provider, [:kind, :aws, :provided]),
      kube_provider_config: %{},
      default_size: sequence(:default_size, [:tiny, :small, :medium, :large, :xlarge, :huge]),
      control_jwk: CommonCore.JWK.generate_key()
    }
  end

  def register_user!(user) do
    user = Map.put(user, :terms, true)
    {:ok, user} = Accounts.register_user(user)
    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
