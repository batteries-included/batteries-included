defmodule CommonCore.Installs.HomeBaseInitData do
  @moduledoc false
  use CommonCore, :embedded_schema

  batt_embedded_schema do
    embeds_many :installs, CommonCore.Installation
    embeds_many :teams, CommonCore.Teams.Team
  end
end
