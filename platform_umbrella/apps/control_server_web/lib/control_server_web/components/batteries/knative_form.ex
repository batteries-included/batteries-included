defmodule ControlServerWeb.Batteries.KnativeForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        <%= @battery.description %>
      </.panel>

      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:namespace]} label="Namespace" disabled={@action != :new} />
        </.simple_form>
      </.panel>

      <.panel title="Images">
        <.simple_form variant="nested">
          <.image>
            <%= @form[:queue_image].value %><br />
            <%= @form[:activator_image].value %><br />
            <%= @form[:autoscaler_image].value %><br />
            <%= @form[:controller_image].value %><br />
            <%= @form[:webhook_image].value %><br />
            <%= @form[:istio_controller_image].value %><br />
            <%= @form[:istio_webhook_image].value %>
          </.image>

          <.image_version
            field={@form[:queue_image_tag_override]}
            image_id={:knative_serving_queue}
            label="Queue Version"
          />

          <.image_version
            field={@form[:activator_image_tag_override]}
            image_id={:knative_serving_activator}
            label="Activator Version"
          />

          <.image_version
            field={@form[:autoscaler_image_tag_override]}
            image_id={:knative_serving_autoscaler}
            label="Autoscaler Version"
          />

          <.image_version
            field={@form[:controller_image_tag_override]}
            image_id={:knative_serving_controller}
            label="Controller Version"
          />

          <.image_version
            field={@form[:webhook_image_tag_override]}
            image_id={:knative_serving_webhook}
            label="Webhook Version"
          />

          <.image_version
            field={@form[:istio_controller_image_tag_override]}
            image_id={:knative_istio_controller}
            label="Istio Controller Version"
          />

          <.image_version
            field={@form[:istio_webhook_image_tag_override]}
            image_id={:knative_istio_webhook}
            label="Istio Webhook Version"
          />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
