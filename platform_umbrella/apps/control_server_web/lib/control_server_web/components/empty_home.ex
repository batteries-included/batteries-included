defmodule ControlServerWeb.EmptyHome do
  @moduledoc false
  use ControlServerWeb, :html

  attr :install_path, :string, required: true

  @doc """
  This component is renders an empty state for when no services have been
  installed on the kubernetes cluster. It uses tailwindcss and the smiley-face icon
  to welcome the user to install batteries.
  """
  def empty_home(assigns) do
    ~H"""
    <.flex class="flex-col items-center justify-center h-full">
      <PC.icon name={:face_smile} class="h-10 lg:h-28 w-auto" />
      <.h2>Welcome to Batteries Included</.h2>
      <span class="max-w-96">
        There are no batteries installed for this group. Each
        running battery brings a new feature, power, or service to the
        platform. Addtitionally new batteries will bring extra
        powers to previously installed batteries, thanks to the automatic
        integrations between batteries.
      </span>
      <PC.button to={@install_path} link_type="a">
        Install Batteries
      </PC.button>
    </.flex>
    """
  end
end
