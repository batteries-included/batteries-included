defmodule CommonCore.Batteries.KnativeConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :knative do
    field :namespace, :string, default: Defaults.Namespaces.knative()

    defaultable_field :queue_image, :string, default: Defaults.Images.knative_serving_queue_image()
    defaultable_field :activator_image, :string, default: Defaults.Images.knative_serving_activator_image()
    defaultable_field :autoscaler_image, :string, default: Defaults.Images.knative_serving_autoscaler_image()
    defaultable_field :controller_image, :string, default: Defaults.Images.knative_serving_controller_image()
    defaultable_field :webhook_image, :string, default: Defaults.Images.knative_serving_webhook_image()

    defaultable_field :istio_controller_image, :string, default: Defaults.Images.knative_istio_controller_image()
    defaultable_field :istio_webhook_image, :string, default: Defaults.Images.knative_istio_webhook_image()

    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1
  end
end
