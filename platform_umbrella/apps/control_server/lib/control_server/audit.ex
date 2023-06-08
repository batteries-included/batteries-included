defmodule ControlServer.Audit do
  import Ecto.Query, warn: false
  alias ControlServer.Repo
  alias CommonCore.Audit.EditVersion

  def list_edit_versions do
    EditVersion
    |> order_by(desc: :recorded_at)
    |> Repo.all()
  end
end
