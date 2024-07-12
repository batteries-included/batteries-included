defmodule CommonCore.ET.StableVersionsReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :control_server, :string, default: CommonCore.Defaults.Images.control_server_image()
  end
end
