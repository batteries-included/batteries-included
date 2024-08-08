defmodule ControlServer.Audit do
  @moduledoc false

  use ControlServer, :context

  alias CommonCore.Audit.EditVersion

  def list_edit_versions do
    EditVersion
    |> order_by(desc: :recorded_at)
    |> Repo.all()
  end

  def list_edit_versions(params) do
    Repo.Flop.validate_and_run(EditVersion, params, for: EditVersion)
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
