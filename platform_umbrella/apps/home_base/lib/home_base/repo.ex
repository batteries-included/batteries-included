defmodule HomeBase.Repo do
  use Ecto.Repo,
    otp_app: :home_base,
    adapter: Ecto.Adapters.Postgres

  use ExAudit.Repo
  use Ecto.SoftDelete.Repo
end
