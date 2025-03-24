defmodule CommonCore.Postgres.PGBackupConfig do
  @moduledoc false
  use CommonCore, :embedded_schema

  import CommonCore.Util.Tuple

  @backup_types [
    none: "None",
    object_store: "Object Store"
  ]

  batt_embedded_schema do
    field :type, Ecto.Enum, values: Keyword.keys(@backup_types)
  end

  def backup_type_options_for_select, do: Enum.map(@backup_types, &swap/1)
end
