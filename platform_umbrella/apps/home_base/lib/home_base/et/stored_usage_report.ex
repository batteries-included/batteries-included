defmodule HomeBase.ET.StoredUsageReport do
  @moduledoc false
  use CommonCore, {:schema, no_encode: [:installation]}

  @required_fields ~w(report installation_id)a

  @derive {
    Flop.Schema,
    filterable: [:id], sortable: [:id, :inserted_at]
  }

  batt_schema "stored_usage_reports" do
    # Every usage report belongs to a single installation
    # That installation reported how many pods were used
    belongs_to :installation, CommonCore.Installation

    # This is what the install told us
    embeds_one :report, CommonCore.ET.UsageReport, on_replace: :delete

    # This is when they told us
    timestamps()
  end
end
