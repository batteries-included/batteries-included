defmodule ControlServer.Repo do
  use Ecto.Repo,
    otp_app: :control_server,
    adapter: Ecto.Adapters.Postgres

  use ExAudit.Repo
end

defmodule ControlServer.Repo.Flop do
  use Flop, repo: ControlServer.Repo
end
