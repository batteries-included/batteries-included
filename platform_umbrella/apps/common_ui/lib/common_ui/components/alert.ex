defmodule CommonUI.Components.Alert do
  @moduledoc false
  use CommonUI, :component
  use Gettext, backend: CommonUI.Gettext, warn: false

  import CommonUI.Components.Icon

  alias CommonUI.IDHelpers

  attr :id, :string
  attr :variant, :string, default: "info", values: ["info", "success", "warning", "error", "disconnected"]
  attr :type, :string, default: "inline", values: ["inline", "fixed"]
  attr :position, :string, default: "bottom-right", values: ["top-left", "top-right", "bottom-left", "bottom-right"]
  attr :autoshow, :boolean, default: true
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block

  def alert(assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div
      id={@id}
      role="alert"
      phx-mounted={@autoshow && @type == "fixed" && show_alert(@id)}
      class={[
        "flex items-start gap-3 rounded-lg text-sm font-semibold border group",
        type_class(@type),
        position_class(@position),
        variant_class(@variant),
        @class
      ]}
      {@rest}
    >
      <.icon
        solid
        name={icon_name(@variant)}
        class={[@variant == "disconnected" && "animate-spin", icon_class()]}
      />

      <%= if @variant == "disconnected" do %>
        Attempting to reconnect
      <% else %>
        <div class="flex-1">
          <%= render_slot(@inner_block) %>
        </div>

        <.icon
          :if={@type == "fixed"}
          name={:x_mark}
          class={["cursor-pointer hover:opacity-60", icon_class()]}
          phx-click={hide_alert(@id)}
        />
      <% end %>
    </div>
    """
  end

  def show_alert(selector \\ nil) do
    to = if selector, do: "##{selector}"

    JS.show(
      to: to,
      time: 200,
      display: "flex",
      transition: {
        "transition-all transform ease-out duration-200",
        "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
        "opacity-100 translate-y-0 sm:scale-100"
      }
    )
  end

  def hide_alert(selector \\ nil) do
    to = if selector, do: "##{selector}"

    JS.hide(
      to: to,
      time: 100,
      transition: {
        "transition-all transform ease-in duration-100",
        "opacity-100 translate-y-0 sm:scale-100",
        "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
      }
    )
  end

  defp type_class("inline"), do: "px-3.5 py-2.5"

  defp type_class("fixed") do
    "fixed shadow-lg z-50 max-w-96 px-5 py-4 shadow-xl shadow-gray-darkest/10 z-50 hidden"
  end

  defp variant_class("info") do
    "bg-sky-50 text-sky-500 border-sky-100 dark:bg-sky-500 dark:text-white dark:border-none"
  end

  defp variant_class("success") do
    "bg-green-50 text-green-500 border-green-100 dark:bg-green-500 dark:text-white dark:border-none"
  end

  defp variant_class("warning") do
    "bg-amber-50 text-amber-500 border-amber-100 dark:bg-amber-400 dark:text-white dark:border-none"
  end

  defp variant_class("error") do
    "bg-red-50 text-red-500 border-red-100 dark:bg-red-500 dark:text-white dark:border-none"
  end

  defp variant_class("disconnected"), do: variant_class("error")

  defp position_class("top-left"), do: "top-5 left-5"
  defp position_class("top-right"), do: "top-5 right-5"
  defp position_class("bottom-left"), do: "bottom-5 left-5"
  defp position_class("bottom-right"), do: "bottom-5 right-5"

  defp icon_class, do: "size-5 shrink-0"

  defp icon_name("info"), do: :information_circle
  defp icon_name("success"), do: :check_circle
  defp icon_name("warning"), do: :exclamation_triangle
  defp icon_name("error"), do: :exclamation_circle
  defp icon_name("disconnected"), do: :arrow_path
end
