defmodule ControlServerWeb.Batteries.SSOForm do
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
          <.input field={@form[:dev]} type="switch" label="Dev" />
        </.simple_form>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:oauth2_proxy_image].value %></.image>

          <.image_version
            field={@form[:oauth2_proxy_image_tag_override]}
            image_id={:oauth2_proxy}
            label="OAuth2 Proxy Version"
          />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
