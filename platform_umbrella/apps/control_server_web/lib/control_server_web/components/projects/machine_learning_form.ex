defmodule ControlServerWeb.Projects.MachineLearningForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:form, to_form(%{}))}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    send(self(), {:next, {__MODULE__, %{}}})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.simple_form
        id={@id}
        for={@form}
        class={@class}
        variant="stepped"
        title="Machine Learning"
        description="A place for information about the machine learning stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
