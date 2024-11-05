defmodule HomeBase.ET.StoredHostReport do
  @moduledoc false
  use CommonCore, {:schema, no_encode: [:installation]}

  import Ecto.SoftDelete.Schema

  @required_fields ~w(report installation_id)a

  batt_schema "stored_host_reports" do
    # Every usage report belongs to a single installation
    # That installation reported how many pods were used
    belongs_to :installation, CommonCore.Installation

    # This is what the install told us
    embeds_one :report, CommonCore.ET.HostReport, on_replace: :delete

    # This is when they told us
    timestamps()

    soft_delete_schema()
  end
end
