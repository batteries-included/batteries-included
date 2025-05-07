defmodule CommonUI.Components.Pagination do
  @moduledoc false
  use CommonUI, :component

  import CommonUI.Components.Icon

  attr :meta, :list, required: true
  attr :path, :string, default: nil
  attr :class, :any, default: nil
  attr :scroll_to_id, :string, default: nil

  def pagination(assigns) do
    ~H"""
    <div class={["inline-flex items-center border border-gray-lighter rounded-md", @class]}>
      <div class={[
        "px-4 py-0.5",
        (@meta.has_next_page? || @meta.has_previous_page?) && "border-r border-r-gray-lighter"
      ]}>
        <span class="font-semibold">{current_page_range(@meta)}</span>
        <span class="text-gray-light">of {@meta.total_count}</span>
      </div>

      <Flop.Phoenix.pagination
        :if={@path}
        meta={@meta}
        path={@path}
        class="pagination"
        current_page_link_attrs={[class: "is-current"]}
        on_paginate={@scroll_to_id && JS.dispatch("scroll_to", to: "##{@scroll_to_id}")}
      >
        <:previous attrs={[class: "previous"]}>
          <.icon name={:chevron_left} class="size-4" />
        </:previous>
        <:next attrs={[class: "next"]}>
          <.icon name={:chevron_right} class="size-4" />
        </:next>
      </Flop.Phoenix.pagination>
    </div>
    """
  end

  def pagination_prev do
    assigns = %{}

    ~H"""
    <.icon name={:chevron_left} class="size-5" mini />
    """
  end

  def pagination_next do
    assigns = %{}

    ~H"""
    <.icon name={:chevron_right} class="size-5" mini />
    """
  end

  defp current_page_range(meta) do
    low = meta.current_offset + 1
    high = min(meta.total_count, meta.current_page * meta.page_size)

    cond do
      low > meta.total_count -> 0
      low == high -> low
      true -> "#{low}-#{high}"
    end
  end
end
