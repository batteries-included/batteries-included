defmodule HomeBase.Repo do
  use Ecto.Repo,
    otp_app: :home_base,
    adapter:
      if(Mix.env() in [:integration],
        do: Ecto.Adapters.SQLite3,
        else: Ecto.Adapters.Postgres
      )

  use ExAudit.Repo
end
