defmodule CommonUI.Components.InputList do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Button

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, default: nil
  attr :add_label, :string, default: "Add"
  attr :add_click, :any, default: nil
  attr :remove_click, :any, default: nil
  attr :phx_target, :any, default: nil
  attr :sort_param, :string
  attr :drop_param, :string

  slot :inner_block, required: true

  def input_list(%{sort_param: _, drop_param: _} = assigns) do
    ~H"""
    <div>
      <div :if={@label} class={label_class()}><%= @label %></div>

      <.inputs_for :let={f} field={@field}>
        <input type="hidden" name={"#{@field.form.name}[#{@sort_param}][]"} value={f.index} />

        <div class={wrapper_class()}>
          <div class="flex-1">
            <%= render_slot(@inner_block, f) %>
          </div>

          <.button
            variant="minimal"
            icon={:x_mark}
            name={"#{@field.form.name}[#{@drop_param}][]"}
            value={f.index}
            phx-click={JS.dispatch("change")}
          />
        </div>
      </.inputs_for>

      <input type="hidden" name={"#{@field.form.name}[#{@drop_param}][]"} />

      <.button
        variant="minimal"
        icon={:plus}
        class="mt-4"
        name={"#{@field.form.name}[#{@sort_param}][]"}
        value="new"
        phx-click={JS.dispatch("change")}
      >
        <%= @add_label %>
      </.button>
    </div>
    """
  end

  def input_list(assigns) do
    ~H"""
    <div>
      <div :if={@label} class={label_class()}><%= @label %></div>

      <%= if @field.value == [] do %>
        <input type="hidden" name={"#{@field.name}[]"} />
      <% else %>
        <%= for {value, index} <- Enum.with_index(@field.value) do %>
          <div class={wrapper_class()}>
            <div class="flex-1">
              <%= render_slot(
                @inner_block,
                Map.merge(@field, %{name: @field.name <> "[]", value: value})
              ) %>
            </div>

            <.button
              variant="minimal"
              icon={:x_mark}
              phx-value-index={index}
              phx-click={@remove_click}
              phx-target={@phx_target}
            />
          </div>
        <% end %>
      <% end %>

      <.button
        variant="minimal"
        icon={:plus}
        class="mt-3 text-gray-light"
        phx-click={@add_click}
        phx-target={@phx_target}
      >
        <%= @add_label %>
      </.button>
    </div>
    """
  end

  defp label_class, do: "text-sm text-gray-darkest dark:text-gray-lighter mb-2"
  defp wrapper_class, do: "flex items-center justify-between gap-4 lg:gap-6 mb-2 last:mb-0"
end
