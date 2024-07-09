defmodule ControlServerWeb.EmptyHome do
  @moduledoc false
  use ControlServerWeb, :html

  attr :icon, :atom, default: :face_smile
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
      <.icon name={@icon} class="size-60 text-primary opacity-15" />

      <p class="text-gray-light text-lg font-medium max-w-md mb-12">
        There are no batteries installed for this group. Each battery brings a new feature or service to the platform, as well as automatic integrations between previously installed batteries for even more power.
      </p>

      <.button variant="primary" link={@install_path}>
        Install Batteries
      </.button>
    </.flex>
    """
  end
end
