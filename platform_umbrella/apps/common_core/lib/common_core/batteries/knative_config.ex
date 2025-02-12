defmodule CommonCore.Batteries.KnativeConfig do
  @moduledoc false

  use CommonCore, {:embedded_schema, no_encode: [:cookie_secret]}

  alias CommonCore.Defaults

  batt_polymorphic_schema type: :knative do
    field :namespace, :string, default: Defaults.Namespaces.knative()

    defaultable_image_field :queue_image, image_id: :knative_serving_queue
    defaultable_image_field :activator_image, image_id: :knative_serving_activator
    defaultable_image_field :autoscaler_image, image_id: :knative_serving_autoscaler
    defaultable_image_field :controller_image, image_id: :knative_serving_controller
    defaultable_image_field :webhook_image, image_id: :knative_serving_webhook

    defaultable_image_field :istio_controller_image, image_id: :knative_istio_controller
    defaultable_image_field :istio_webhook_image, image_id: :knative_istio_webhook

    secret_field :cookie_secret, length: 32, func: &Defaults.urlsafe_random_key_string/1
  end
end
