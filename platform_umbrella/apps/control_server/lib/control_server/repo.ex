defmodule ControlServer.Repo do
  use Ecto.Repo,
    otp_app: :control_server,
    adapter: Ecto.Adapters.Postgres
end
