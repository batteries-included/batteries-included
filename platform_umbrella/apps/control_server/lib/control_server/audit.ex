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
end
