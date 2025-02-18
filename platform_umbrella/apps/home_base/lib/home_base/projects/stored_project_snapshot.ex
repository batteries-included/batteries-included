defmodule HomeBase.Projects.StoredProjectSnapshot do
  @moduledoc false
  use CommonCore, {:schema, no_encode: [:installation]}

  import Ecto.SoftDelete.Schema

  @required_fields ~w()a

  batt_schema "stored_project_snapshots" do
    belongs_to :installation, CommonCore.Installation

    embeds_one :snapshot, CommonCore.Projects.ProjectSnapshot, on_replace: :delete

    # This is when they told us
    timestamps()

    soft_delete_schema()
  end

  @spec name(t()) :: String.t()
  def name(%__MODULE__{snapshot: snapshot}) do
    snapshot.name
  end
end
