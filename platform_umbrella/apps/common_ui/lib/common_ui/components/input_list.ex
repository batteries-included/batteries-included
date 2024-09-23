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

  @doc """
  This component is meant to be used with list schema attributes
  such as array, has_many, or embeds_many. If using `has_many` or
  `embeds_many`, `sort_param` and `drop_param` attributes should
  be passed that are also used in the schema's changeset.

  ## Example

      def changeset(struct, attrs \\ %{}) do
        struct
        |> cast(attrs, [:foo])
        |> cast_assoc(:bar, with: &Bar.changeset/2, sort_param: :sort_bar, drop_param: :drop_bar)
      end

      <.input_list
        :let={f}
        field={@form[:bar]}
        sort_param={:sort_bar}
        drop_param={:drop_bar}
      >
        <.input field={f} />
      </.input_list>

  If using `{:array, type}`, the sort and drop params are not
  needed, but the click events need to be handled manually.

      def handle_event("add-item", params, socket) do
        bars = Changeset.get_field(socket.assigns.form.source, :bars) || []

        form =
          socket.assigns.form.source
          |> Changeset.put_change(:bars, bars ++ [""])
          |> to_form()

        {:noreply, assign(socket, :form, form)}
      end

      <.input_list
        :let={f}
        field={@form[:bar]}
        add_click="add-item"
        remove_click="remove-item"
        phx_target={@myself}
      >
        <.input field={f} />
      </.input_list>

  """
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

      <.list :let={{value, index}} field={@field}>
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
      </.list>

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

  defp list(%{field: %{value: nil}} = assigns) do
    ~H"""
    """
  end

  defp list(%{field: %{value: []}} = assigns) do
    ~H"""
    <input type="hidden" name={"#{@field.name}[]"} />
    """
  end

  defp list(assigns) do
    ~H"""
    <%= for {value, index} <- Enum.with_index(@field.value) do %>
      <%= render_slot(@inner_block, {value, index}) %>
    <% end %>
    """
  end

  defp label_class, do: "text-sm text-gray-darkest dark:text-gray-lighter mb-2"
  defp wrapper_class, do: "flex items-center justify-between gap-4 lg:gap-6 mb-2 last:mb-0"
end
