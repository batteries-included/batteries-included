defmodule ControlServerWeb.Batteries.CertManagerForm do
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
          <.input field={@form[:email]} label="Email" />
        </.simple_form>
      </.panel>

      <.panel title="Images">
        <.simple_form variant="nested">
          <.image>
            <%= @form[:acmesolver_image].value %><br />
            <%= @form[:cainjector_image].value %><br />
            <%= @form[:controller_image].value %><br />
            <%= @form[:ctl_image].value %><br />
            <%= @form[:webhook_image].value %>
          </.image>

          <.image_version
            field={@form[:acmesolver_image_tag_override]}
            image_id={:cert_manager_acmesolver}
            label="ACME Solver Version"
          />

          <.image_version
            field={@form[:cainjector_image_tag_override]}
            image_id={:cert_manager_cainjector}
            label="CA Injector Version"
          />

          <.image_version
            field={@form[:controller_image_tag_override]}
            image_id={:cert_manager_controller}
            label="Controller Version"
          />

          <.image_version
            field={@form[:ctl_image_tag_override]}
            image_id={:cert_manager_ctl}
            label="CTL Version"
          />

          <.image_version
            field={@form[:webhook_image_tag_override]}
            image_id={:cert_manager_webhook}
            label="Webhook Version"
          />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
