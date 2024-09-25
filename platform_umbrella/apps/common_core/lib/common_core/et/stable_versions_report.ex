defmodule CommonCore.ET.StableVersionsReport do
  @moduledoc false
  use CommonCore, :embedded_schema

  batt_embedded_schema do
    field :control_server, :string, default: CommonCore.Defaults.Images.control_server_image()
    field :bi, :string, default: CommonCore.Defaults.Versions.bi_stable_version()
  end
end
