defmodule ControlServerWeb.KnativeFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryURLs

  alias Ecto.Changeset
  alias Phoenix.HTML.Form

  attr :class, :any, default: nil
  attr :form, Form, required: true

  def main_panel(assigns) do
    ~H"""
    <div class={["contents", @class]}>
      <.fieldset>
        <.field>
          <:label>Name</:label>
          <.input field={@form[:name]} placeholder="Name" autofocus />
        </.field>

        <.field>
          <:label>URL</:label>
          <.input name="url" value={potential_url(@form)} disabled />
        </.field>

        <.input type="radio" field={@form[:kube_internal]}>
          <:option value="true">Internal</:option>
          <:option value="false">External</:option>
        </.input>
      </.fieldset>
    </div>
    """
  end

  defp potential_url(%Form{} = form), do: knative_service_url(Changeset.apply_changes(form.source))
end
