defmodule ControlServerWeb.KnativeFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  import KubeServices.SystemState.SummaryHosts

  alias Ecto.Changeset
  alias Phoenix.HTML.Form

  attr :class, :any, default: nil
  attr :form, Form, required: true

  def main_panel(assigns) do
    ~H"""
    <div class={["contents", @class]}>
      <.grid columns={[sm: 1, lg: 2]}>
        <.input label="Name" field={@form[:name]} autofocus placeholder="Name" />

        <.flex class="justify-around items-center">
          <.truncate_tooltip value={potential_url(@form)} length={72} />
        </.flex>
      </.grid>
    </div>
    """
  end

  defp potential_url(%Form{} = form) do
    "http://#{knative_host(Changeset.apply_changes(form.source))}"
  end
end
