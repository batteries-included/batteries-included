defmodule ControlServerWeb.Batteries.TrustManagerForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        <%= @battery.description %>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>
            <%= @form[:image].value %><br />
            <%= @form[:init_image].value %>
          </.image>

          <.image_version
            field={@form[:image_tag_override]}
            image_id={:trust_manager}
            label="Version"
          />

          <.image_version
            field={@form[:init_image_tag_override]}
            image_id={:trust_manager_init}
            label="Init Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
