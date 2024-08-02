defmodule CommonCore.Containers.Mount do
  @moduledoc false

  use CommonCore, :embedded_schema

  @required_fields ~w(volume_name mount_path)a

  batt_embedded_schema do
    field :volume_name, :string
    field :mount_path, :string
    field :read_only, :boolean, default: false
  end
end
