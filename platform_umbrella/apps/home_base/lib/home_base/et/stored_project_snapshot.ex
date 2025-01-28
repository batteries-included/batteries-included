defmodule HomeBase.ET.StoredProjectSnapshot do
  @moduledoc false
  use CommonCore, {:schema, no_encode: [:installation]}

  import Ecto.SoftDelete.Schema

  @required_fields ~w()a

  batt_schema "stored_project_snapshots" do
    belongs_to :installation, CommonCore.Installation

    embeds_one :report, CommonCore.ET.ProjectSnapshot, on_replace: :delete

    # This is when they told us
    timestamps()

    soft_delete_schema()
  end
end
