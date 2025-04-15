defmodule CommonUI.Components.Table do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Input
  import CommonUI.Components.Pagination

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :variant, :string, values: ["paginated"]
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  # Used for Flop.Phoenix
  attr :path, :string
  attr :meta, :map, default: %{}
  attr :opts, :list, default: []

  slot :col, required: true do
    attr :field, :atom
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(%{variant: "paginated"} = assigns) do
    assigns =
      if assigns.row_click do
        tbody_tr_attrs =
          assigns.opts
          |> Keyword.get(:tbody_tr_attrs, [])
          |> Keyword.put(:class, tbody_tr_class())

        assign(assigns, :opts, Keyword.put(assigns.opts, :tbody_tr_attrs, tbody_tr_attrs))
      else
        assigns
      end

    ~H"""
    <Flop.Phoenix.table
      id={@id}
      items={@rows}
      row_id={@row_id}
      row_click={@row_click}
      row_item={@row_item}
      path={@path}
      meta={@meta}
      opts={@opts}
    >
      <:col :let={item} :for={col <- @col} field={col.field} label={col.label}>
        {render_slot(col, item)}
      </:col>

      <:col :let={item} :if={@action != []}>
        <div class={actions_class()}>
          {render_slot(@action, item)}
        </div>
      </:col>
    </Flop.Phoenix.table>

    <div class="flex justify-end gap-3 mt-6">
      <.pagination meta={@meta} path={@path} scroll_to_id={@id} />
    </div>
    """
  end

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={container_class()}>
      <table id={@id} class={table_class()}>
        <thead class={thead_class()}>
          <tr>
            <th :for={col <- @col} class={thead_th_class()}>{col[:label]}</th>
            <th :if={@action && @action != []} class={thead_th_class()}>
              <span class="sr-only">Actions</span>
            </th>
          </tr>
        </thead>

        <tbody
          id={"#{@id}-body"}
          class={tbody_class()}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
        >
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            {
            maybe_invoke_callback(Keyword.get(@opts, :tbody_tr_attrs, nil), row)
            |> Map.merge(if @row_click, do: tbody_tr_class(), else: %{})
            }
          >
            <td :for={col <- @col} class={tbody_td_class()} phx-click={@row_click && @row_click.(row)}>
              {render_slot(col, @row_item.(row))}
            </td>

            <td :if={@action != []} class={tbody_td_class()}>
              <div class={actions_class()}>
                {render_slot(@action, @row_item.(row))}
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :meta, :map, required: true
  attr :fields, :list, required: true
  attr :placeholder, :string, default: "Filter"
  attr :on_change, :string, required: true
  attr :target, :string, default: nil

  def table_search(%{meta: meta} = assigns) do
    assigns = assign(assigns, form: to_form(meta))

    ~H"""
    <.form for={@form} phx-target={@target} phx-change={@on_change} phx-submit={@on_change}>
      <Flop.Phoenix.filter_fields :let={i} form={@form} fields={@fields}>
        <.input
          field={i.field}
          type={i.type}
          icon={:magnifying_glass}
          placeholder={@placeholder}
          debounce={100}
          {i.rest}
        />
      </Flop.Phoenix.filter_fields>
    </.form>
    """
  end

  defp maybe_invoke_callback(nil, _item), do: %{}

  defp maybe_invoke_callback(callback, item) do
    apply(callback, [item])
  end

  def paginated_table_opts do
    [
      container: true,
      container_attrs: [class: container_class()],
      table_attrs: [class: table_class()],
      thead_attrs: [class: thead_class()],
      thead_th_attrs: [class: thead_th_class()],
      tbody_attrs: [class: tbody_class()],
      tbody_td_attrs: [class: tbody_td_class()],
      no_results_content: nil
    ]
  end

  def pagination_opts do
    [
      page_links: :hide,
      wrapper_attrs: [class: "flex items-center px-2 py-0.5"],
      disabled_class: "text-gray-lighter hover:!text-gray-lighter",
      previous_link_attrs: [class: "mr-1 hover:text-primary"],
      next_link_attrs: [class: "hover:text-primary"],
      previous_link_content: pagination_prev(),
      next_link_content: pagination_next()
    ]
  end

  defp container_class, do: "overflow-y-auto px-4 sm:overflow-visible sm:px-0"
  defp table_class, do: "w-[40rem] mt-4 sm:w-full"

  defp thead_class do
    "text-sm text-left leading-6 text-gray-darker dark:text-gray border-b border-gray-lighter dark:border-gray-darker"
  end

  defp thead_th_class, do: "pb-4"

  defp tbody_class do
    [
      "relative text-sm leading-6 text-gray-darkest dark:text-gray-lighter",
      "before:content-['@'] before:block before:leading-3 before:indent-[-99999px]"
    ]
  end

  defp tbody_tr_class, do: "cursor-pointer hover:bg-gray-lightest dark:hover:bg-gray-darkest-tint"
  defp tbody_td_class, do: "px-2 py-4 align-top first:rounded-l-lg last:rounded-r-lg first:font-semibold"
  defp actions_class, do: "flex items-center justify-end gap-3 lg:gap-4 px-2 whitespace-nowrap text-sm font-semibold"
end
