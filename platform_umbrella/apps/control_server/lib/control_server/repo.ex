defmodule ControlServer.Repo do
  use Ecto.Repo,
    otp_app: :control_server,
    adapter:
      if(Mix.env() in [:integration],
        do: Ecto.Adapters.SQLite3,
        else: Ecto.Adapters.Postgres
      )

  use ExAudit.Repo
end

defmodule ControlServer.Repo.Flop do
  @moduledoc false
  use Flop, repo: ControlServer.Repo
end
