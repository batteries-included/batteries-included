defmodule HomeBase.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: HomeBase.Repo

  alias CommonCore.Accounts.User
  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole
  alias HomeBase.Accounts
  alias HomeBase.ET.StoredUsageReport

  def stored_usage_report_factory do
    %StoredUsageReport{
      report: CommonCore.Factory.usage_report_factory()
    }
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
