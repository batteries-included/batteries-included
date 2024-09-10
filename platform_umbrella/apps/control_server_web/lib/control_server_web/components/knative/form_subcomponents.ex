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
      <.flex column>
        <.input label="Name" field={@form[:name]} autofocus placeholder="Name" />
        <.input label="URL" name="url" value={potential_url(@form)} disabled />

        <.input field={@form[:kube_internal]} type="radio">
          <:option value="true">Internal</:option>
          <:option value="false">External</:option>
        </.input>
      </.flex>
    </div>
    """
  end

  defp potential_url(%Form{} = form), do: knative_service_url(Changeset.apply_changes(form.source))
end
