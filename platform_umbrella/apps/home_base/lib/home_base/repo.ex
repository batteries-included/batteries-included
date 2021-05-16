defmodule HomeBase.Repo do
  use Ecto.Repo,
    otp_app: :home_base,
    adapter: Ecto.Adapters.Postgres
end
