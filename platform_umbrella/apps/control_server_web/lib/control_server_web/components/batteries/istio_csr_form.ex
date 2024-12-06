defmodule ControlServerWeb.Batteries.IstioCSRForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description" class="lg:col-span-2">
        {@battery.description}
      </.panel>
    </div>
    """
  end
end
