defmodule ControlServer.Repo do
  use Ecto.Repo,
    otp_app: :control_server,
    adapter: Ecto.Adapters.Postgres

  use ExAudit.Repo
end

defmodule ControlServer.Repo.Flop do
  @moduledoc false
  use Flop, repo: ControlServer.Repo, default_limit: 20, max_limit: 100
end
