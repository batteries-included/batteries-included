defmodule CommonUI.Components.FlashGroup do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Alert

  alias CommonUI.IDHelpers
  alias Phoenix.Flash

  attr :id, :string
  attr :flash, :map, default: %{}
  attr :global, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  def flash_group(assigns) do
    assigns = IDHelpers.provide_id(assigns)

    ~H"""
    <div :if={@flash != %{}} class={[flash_group_class(@global), @class]} {@rest}>
      <%= if @global do %>
        <.alert
          :for={variant <- alert_variants()}
          :if={msg = Flash.get(@flash, "global_" <> variant)}
          id={"#{@id}-#{variant}"}
          variant={variant}
          type="fixed"
          class="relative mb-3 last:mb-0"
        >
          {msg}
        </.alert>
      <% else %>
        <.alert
          :for={variant <- alert_variants()}
          :if={msg = Flash.get(@flash, variant)}
          id={"#{@id}-#{variant}"}
          variant={variant}
          class="mb-3 last:mb-0"
        >
          {msg}
        </.alert>
      <% end %>
    </div>
    """
  end

  defp flash_group_class(true), do: "fixed bottom-0 right-0 z-50"
  defp flash_group_class(false), do: ""

  defp alert_variants, do: ["info", "success", "warning", "error"]
end
