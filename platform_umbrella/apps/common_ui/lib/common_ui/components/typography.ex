defmodule CommonUI.Components.Typography do
  @moduledoc false
  use CommonUI, :component

  attr :class, :any, default: ""
  attr :base_class, :string, default: "text-3xl text-primary sm:text-5xl font-extrabold my-6"
  attr :sep_class, :string, default: "m-0 text-gray-darkest"
  attr :sub_header_class, :string, default: "font-mono"
  slot :inner_block, required: true, doc: "The main text of the header"
  slot :sub_header, required: false, doc: "The sub text of the header"
  attr :rest, :global

  def h1(%{sub_header: []} = assigns) do
    ~H"""
    <h1 class={[@base_class, @class]} {@rest}>
      {render_slot(@inner_block)}
    </h1>
    """
  end

  def h1(%{} = assigns) do
    ~H"""
    <h1 class={[@base_class, @class]} {@rest}>
      {render_slot(@inner_block)}<span class={@sep_class}>::<span class={@sub_header_class}><%= render_slot(@sub_header) %></span></span>
    </h1>
    """
  end

  attr :class, :any, default: ""
  attr :base_class, :string, default: "text-xl sm:text-3xl font-semibold my-3"
  attr :color_class, :string, default: "text-gray-darkest dark:text-gray-lighter"

  attr :fancy_class, :string, default: "text-transparent bg-clip-text bg-gradient-to-br from-primary to-cyan-700"

  attr :variant, :string, default: "default", values: ["default", "fancy"]
  slot :inner_block, required: true
  attr :rest, :global

  def h2(%{variant: "fancy"} = assigns) do
    ~H"""
    <h2 class={[@base_class, @class]} {@rest}>
      <span class={[@fancy_class]}>
        {render_slot(@inner_block)}
      </span>
    </h2>
    """
  end

  def h2(%{variant: _} = assigns) do
    ~H"""
    <h2 class={[@base_class, @color_class, @class]} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr :class, :any, default: ""
  attr :base_class, :string, default: "text-xl font-medium text-gray-darker dark:text-white"
  slot :inner_block, required: true
  attr :rest, :global

  def h3(assigns) do
    ~H"""
    <h3 class={[@base_class, @class]} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  attr :class, :any, default: ""

  attr :base_class, :string, default: "text-lg sm:text-xl uppercase text-semibold text-gray-darkest dark:text-gray-light"

  slot :inner_block, required: true
  attr :rest, :global

  def h4(assigns) do
    ~H"""
    <h4 class={[@base_class, @class]} {@rest}>
      {render_slot(@inner_block)}
    </h4>
    """
  end

  attr :base_class, :string, default: "text-base font-medium text-gray-darkest dark:text-gray-light"
  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, required: true

  def h5(assigns) do
    ~H"""
    <h5 class={[@base_class, @class]} {@rest}>
      {render_slot(@inner_block)}
    </h5>
    """
  end

  attr :rest, :global
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def light_text(assigns) do
    ~H"""
    <div class={["text-gray-dark text-sm dark:text-gray", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
