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
        <.fieldset>
          <.field>
            <:label>Queue Name</:label>
            <.input field={@form[:queue_name]} />
          </.field>

          <.field>
            <:label>Service Role ARN</:label>
            <.input field={@form[:service_role_arn]} />
          </.field>

          <.field>
            <:label>Node Role Name</:label>
            <.input field={@form[:node_role_name]} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image><%= @form[:image].value %></.image>
          <.image_version field={@form[:image_tag_override]} image_id={:karpenter} label="Version" />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
