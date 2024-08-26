defmodule ControlServerWeb.Batteries.TextGenerationWebUIForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.empty_config form={@form} />
    </div>
    """
  end
end