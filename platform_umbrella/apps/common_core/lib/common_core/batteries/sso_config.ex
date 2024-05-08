defmodule CommonCore.Batteries.SSOConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :sso do
    defaultable_field :dev, :boolean, default: true
  end
end
