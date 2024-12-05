defmodule ControlServerWeb.Batteries.SSOForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        {@battery.description}
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field variant="beside">
            <:label>Require MFA?</:label>
            <.input type="switch" field={@form[:mfa]} />
          </.field>
        </.fieldset>
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>{@form[:oauth2_proxy_image].value}</.image>

          <.image_version
            field={@form[:oauth2_proxy_image_tag_override]}
            image_id={:oauth2_proxy}
            label="OAuth2 Proxy Version"
          />
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
