defmodule ControlServerWeb.IFrame do
  use Phoenix.Component

  def iframe(assigns) do
    assigns =
      assigns
      |> assign_new(:src, fn -> nil end)
      |> assign_new(:id, fn -> "main_IFrame" end)

    ~H"""
    <iframe src={@src} class="iframe-container" phx-hook="IFrame" id={@id} />
    """
  end
end
