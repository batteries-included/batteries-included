defmodule CommonCore.TraditionalServices.ConfigMapConfig do
  @moduledoc false
  use CommonCore, :embedded_schema

  @required_fields ~w(name)a

  batt_polymorphic_schema type: :config_map do
    field :default_mode, :integer
    field :name, :string
    field :optional, :boolean, default: false
  end
end
