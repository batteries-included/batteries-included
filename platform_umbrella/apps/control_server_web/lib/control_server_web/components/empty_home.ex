defmodule ControlServerWeb.EmptyHome do
  @moduledoc false
  use ControlServerWeb, :html

  attr :install_path, :string, required: true

  slot :header

  @doc """
  This component is renders an empty state for when no services have been
  installed on the kubernetes cluster. It uses tailwindcss and the smiley-face icon
  to welcome the user to install batteries.
  """
  def empty_home(assigns) do
    ~H"""
    <.flex column class="items-center justify-center h-full text-gray-darkest dark:text-gray-lighter">
      <.icon name={:face_smile} class="h-10 lg:h-28 w-auto" />

      <%= if @header != [] do %>
        <%= render_slot(@header) %>
      <% else %>
        <.h2>Welcome to Batteries Included</.h2>
      <% end %>

      <p class="max-w-lg mb-8">
        There are no batteries installed for this group. Each running battery brings a new feature, power, or service to the platform. Addtitionally new batteries will bring extra powers to previously installed batteries, thanks to the automatic integrations between batteries.
      </p>

      <.button variant="primary" link={@install_path}>
        Install Batteries
      </.button>
    </.flex>
    """
  end
end
