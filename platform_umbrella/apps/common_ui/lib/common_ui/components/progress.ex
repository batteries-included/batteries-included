defmodule CommonUI.Components.Progress do
  @moduledoc false
  use CommonUI, :component

  attr :variant, :string, values: ["stepped"]
  attr :class, :string, default: nil
  attr :current, :integer, required: true
  attr :total, :integer, required: true
  attr :rest, :global

  def progress(%{variant: "stepped"} = assigns) do
    ~H"""
    <div class={["flex gap-4", @class]} {@rest}>
      <div
        :for={i <- 1..@total}
        class={[
          "flex-1 h-1 rounded-lg",
          if(i <= @current, do: "bg-primary", else: "bg-gray-lighter dark:bg-gray-darker")
        ]}
      />
    </div>
    """
  end

  def progress(assigns) do
    ~H"""
    <div class={["h-1 rounded-lg bg-gray-lighter overflow-hidden", @class]} {@rest}>
      <div class="h-full bg-primary" style={"width: #{round((@current / @total) * 100)}%"} />
    </div>
    """
  end
end
