defmodule HomeBase.Repo do
  use Ecto.Repo,
    otp_app: :home_base,
    adapter: Ecto.Adapters.Postgres

  use ExAudit.Repo
  use Ecto.SoftDelete.Repo

  @spec list_with_soft_deleted(Ecto.Queryable.t()) :: [Ecto.Schema.t() | term()]
  @doc """
  Generic method to list a whole collection including soft deleted records.
  """
  def list_with_soft_deleted(queryable) do
    all(queryable, with_deleted: true)
  end
end
