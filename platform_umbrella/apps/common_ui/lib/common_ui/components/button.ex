defmodule CommonUI.Components.Button do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  attr :link, :string
  attr :link_type, :string, default: "redirect", values: ["redirect", "patch", "external"]
  attr :link_replace, :boolean, default: false

  attr :variant, :string, values: ["primary", "secondary", "dark", "danger", "icon", "icon_bordered", "minimal"]
  attr :tag, :string, default: "button"
  attr :class, :string, default: nil
  attr :icon, :atom, default: nil
  attr :icon_position, :atom, default: :left, values: [:left, :right]

  attr :rest, :global,
    include: ~w(form name value id name disabled),
    default: %{
      # Most buttons are either links or use `phx-click`,
      # so change default to "button" rather than "submit".
      type: "button"
    }

  slot :inner_block

  def button(%{link: _} = assigns) do
    {link, assigns} = Map.pop(assigns, :link)
    {link_type, assigns} = Map.pop(assigns, :link_type)
    {link_replace, assigns} = Map.pop(assigns, :link_replace)

    rest =
      assigns.rest
      |> Map.delete(:type)
      |> Map.put(:href, Phoenix.LiveView.Utils.valid_destination!(link, "<.button>"))

    rest =
      if link_type in ~w(redirect patch) do
        rest
        |> Map.put("data-phx-link", link_type)
        |> Map.put("data-phx-link-state", if(link_replace, do: "replace", else: "push"))
      else
        rest
      end

    assigns
    |> Map.merge(%{tag: "a", rest: rest})
    |> button()
  end

  # Hacky solution for https://github.com/phoenixframework/phoenix_live_view/issues/2833
  def button(%{tag: "button"} = assigns) do
    ~H"""
    <button class={[button_class(assigns[:variant]), @class]} {@rest}>
      <.icon
        :if={@icon && @icon_position == :left}
        class={icon_class(assigns[:variant])}
        name={@icon}
      />

      <%= render_slot(@inner_block) %>

      <.icon
        :if={@icon && @icon_position == :right}
        class={icon_class(assigns[:variant])}
        name={@icon}
      />
    </button>
    """
  end

  def button(assigns) do
    ~H"""
    <.dynamic_tag name={@tag} class={[button_class(assigns[:variant]), @class]} {@rest}>
      <.icon
        :if={@icon && @icon_position == :left}
        class={icon_class(assigns[:variant])}
        name={@icon}
      />

      <%= render_slot(@inner_block) %>

      <.icon
        :if={@icon && @icon_position == :right}
        class={icon_class(assigns[:variant])}
        name={@icon}
      />
    </.dynamic_tag>
    """
  end

  defp button_class("primary") do
    [
      button_class(),
      rounded_button_class(),
      "text-white bg-primary hover:bg-primary-dark disabled:bg-gray-lighter dark:disabled:bg-gray-darker/30"
    ]
  end

  defp button_class("secondary") do
    [
      button_class(),
      rounded_button_class(),
      "text-gray-darker dark:text-gray-lighter hover:text-primary dark:hover:text-gray-lighter disabled:text-gray",
      "disabled:hover:text-gray disabled:dark:hover:text-gray",
      "border border-gray-lighter hover:border-primary-light dark:border-gray-darker-tint dark:hover:border-gray-light",
      "disabled:hover:border-gray-lighter disabled:dark:hover:border-gray-darker-tint",
      "bg-white dark:bg-gray-darkest"
    ]
  end

  defp button_class("dark") do
    [
      button_class(),
      rounded_button_class(),
      "text-white dark:text-gray-darkest bg-gray-darkest dark:bg-white hover:bg-gray-darker dark:hover:bg-gray-lighter disabled:bg-gray-lighter"
    ]
  end

  defp button_class("danger") do
    [
      button_class(),
      rounded_button_class(),
      "text-white bg-red-500 hover:bg-red-400 disabled:bg-gray-lighter"
    ]
  end

  defp button_class("icon") do
    [
      button_class(),
      "size-9 p-2 rounded-full text-gray-darker dark:text-gray-lighter hover:text-primary hover:bg-gray-lightest/75 dark:hover:bg-gray-darkest/50 disabled:text-gray"
    ]
  end

  defp button_class("icon_bordered") do
    [
      button_class(),
      "size-9 p-1.5 rounded-lg border border-gray-lighter text-primary hover:border-primary-light",
      "dark:border-gray-darker dark:hover:border-gray-dark",
      "disabled:text-gray disabled:hover:border-gray-lighter"
    ]
  end

  defp button_class("minimal") do
    [
      button_class(),
      "text-gray-dark hover:text-gray disabled:text-gray-light",
      "dark:text-gray dark:hover:text-gray-light dark:disabled:text-gray-dark"
    ]
  end

  defp button_class(_) do
    [
      button_class(),
      "text-primary hover:text-primary-dark disabled:text-gray-light"
    ]
  end

  defp button_class do
    "inline-flex items-center justify-center gap-2 font-semibold text-sm text-nowrap cursor-pointer disabled:cursor-not-allowed phx-submit-loading:opacity-75"
  end

  defp rounded_button_class do
    "min-w-36 px-5 py-3 rounded-lg whitespace-nowrap"
  end

  defp icon_class(_) do
    "size-5 text-current stroke-2 pointer-events-none"
  end
end
