defmodule HomeBase.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: HomeBase.Repo

  alias HomeBase.Accounts
  alias HomeBase.Teams

  def stored_usage_report_factory do
    %HomeBase.ET.StoredUsageReport{
      report: CommonCore.Factory.usage_report_factory()
    }
  end

  def user_factory do
    %Accounts.User{
      email: sequence("user-") <> "@example.com",
      password: "qwer1234",
      hashed_password: "$2b$12$Cx0OPVZ5xwCuHVvQdH1TouyCov581bTNPBQNaJMSJehRH8MrkZgGu"
    }
  end

  def team_factory do
    name = sequence("team-")

    %Teams.Team{
      name: name,
      op_email: "op@#{name}.com"
    }
  end

  def team_role_factory do
    %Teams.TeamRole{
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
