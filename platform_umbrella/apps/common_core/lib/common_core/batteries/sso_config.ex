defmodule CommonCore.Batteries.SSOConfig do
  @moduledoc false

  use CommonCore, :embedded_schema

  batt_polymorphic_schema type: :sso do
    field :mfa, :boolean, default: false

    defaultable_image_field :oauth2_proxy_image, image_id: :oauth2_proxy
  end
end
