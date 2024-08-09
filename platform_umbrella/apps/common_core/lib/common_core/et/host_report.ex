defmodule CommonCore.ET.HostReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  alias CommonCore.Ecto.Schema
  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.Hosts

  @required_fields ~w(control_server_host)a

  batt_embedded_schema do
    field :control_server_host, :string
  end

  def new(%StateSummary{} = state_summary) do
    Schema.schema_new(__MODULE__, control_server_host: Hosts.control_host(state_summary))
  end

  def new(opts) do
    Schema.schema_new(__MODULE__, opts)
  end
end
