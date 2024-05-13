defmodule HomeBase.ET.StoredUsageReport do
  @moduledoc false
  use CommonCore, :schema

  @required_fields ~w(report)a

  batt_schema "stored_usage_reports" do
    field :installation_id, :binary_id
    embeds_one :report, CommonCore.ET.UsageReport, on_replace: :delete

    timestamps()
  end
end
