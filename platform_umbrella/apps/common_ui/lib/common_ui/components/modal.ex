defmodule CommonUI.Components.Modal do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Button

  @doc """
  JS commands may be passed to the `:on_cancel` attribute
  for the caller to react to the button press. For example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        Are you sure you?
        <:actions cancel="Cancel">
          <.button phx-click="delete">OK</.button>
        </:actions>
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :allow_close, :boolean, default: true
  attr :size, :string, default: "md", values: ["md", "lg", "xl"]
  attr :class, :any, default: "p-5"
  attr :on_cancel, JS, default: %JS{}

  slot :title
  slot :inner_block, required: true

  slot :actions do
    attr :cancel, :string
  end

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} class="fixed inset-0 z-50 hidden">
      <div
        id={"#{@id}-bg"}
        aria-hidden="true"
        class="fixed inset-0 z-10 bg-white/80 dark:bg-gray-darkest-tint/80 backdrop-blur-sm transition-all"
      />

      <div
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        aria-modal="true"
        role="dialog"
        tabindex="0"
        class="h-full overflow-y-auto"
      >
        <div class="flex items-center justify-center min-h-full px-4 py-6">
          <.focus_wrap
            id={"#{@id}-container"}
            phx-mounted={@show && show_modal(@id)}
            phx-click-away={@allow_close && hide_modal(@on_cancel, @id)}
            phx-window-keydown={@allow_close && hide_modal(@on_cancel, @id)}
            phx-key="escape"
            class={[
              "relative z-20 w-full bg-white dark:bg-gray-darkest rounded-xl shadow-xl shadow-gray-darkest/10 ring-1 ring-gray-darkest/10 dark:ring-gray-light/10",
              size_class(@size)
            ]}
          >
            <div class="flex items-center justify-between px-5 pt-5">
              <h2
                :if={@title}
                class="text-2xl font-semibold leading-8 text-gray-darkest dark:text-gray-lightest"
              >
                {render_slot(@title)}
              </h2>

              <.button
                :if={@allow_close}
                variant="icon"
                icon={:x_mark}
                aria-label="Close"
                phx-click={hide_modal(@on_cancel, @id)}
              />
            </div>

            <div class={@class}>
              {render_slot(@inner_block)}
            </div>

            <div :if={@actions != []} class="flex items-center justify-end gap-4 px-5 pb-5">
              <%= for action <- @actions do %>
                <.button
                  :if={cancel = Map.get(action, :cancel)}
                  variant="secondary"
                  phx-click={hide_modal(@on_cancel, @id)}
                >
                  {cancel}
                </.button>

                {render_slot(action)}
              <% end %>
            </div>
          </.focus_wrap>
        </div>
      </div>
    </div>
    """
  end

  defp size_class("md"), do: "max-w-xl"
  defp size_class("lg"), do: "max-w-3xl"
  defp size_class("xl"), do: "max-w-5xl"

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.focus_first(to: "##{id}-container")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.pop_focus()
  end
end
