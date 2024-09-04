defmodule ControlServerWeb.Batteries.KarpenterForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        <%= @battery.description %>
      </.panel>

      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input field={@form[:queue_name]} label="Queue Name" />
          <.input field={@form[:service_role_arn]} label="Service Role ARN" />
          <.input field={@form[:node_role_name]} label="Node Role Name" />
        </.simple_form>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:karpenter} label="Version" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
