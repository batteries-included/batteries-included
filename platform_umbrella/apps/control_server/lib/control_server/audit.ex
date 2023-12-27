defmodule ControlServer.Audit do
  @moduledoc false
  import Ecto.Query, warn: false

  alias CommonCore.Audit.EditVersion
  alias ControlServer.Repo

  def list_edit_versions do
    EditVersion
    |> order_by(desc: :recorded_at)
    |> Repo.all()
  end

  def history(%{id: id, __struct__: struct} = _entity, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    EditVersion
    |> from()
    |> where([ev], ev.entity_id == ^id)
    |> where([ev], ev.entity_schema == ^struct)
    |> order_by(desc: :recorded_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_edit_version!(id), do: Repo.get!(EditVersion, id)
end
