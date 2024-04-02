defmodule HomeBase.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: HomeBase.Repo

  def user_factory do
    %HomeBase.Accounts.User{
      email: sequence("user-") <> "@example.com",
      password: "HelloWorld123!"
    }
  end

  def register_user!(user) do
    {:ok, user} = HomeBase.Accounts.register_user(user)
    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
