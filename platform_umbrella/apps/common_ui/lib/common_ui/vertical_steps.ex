defmodule CommonUI.VerticalSteps do
  use CommonUI.Component

  attr :current_step, :integer, default: 0
  attr :base_class, :string, default: "steps steps-vertical"
  attr :class, :string, default: ""
  slot :step, required: true

  def vertical_steps(assigns) do
    ~H"""
    <ul class={build_class([@base_class, @class])}>
      <.step :for={{step, idx} <- Enum.with_index(@step)} step={idx} current_step={@current_step}>
        <%= render_slot(step) %>
      </.step>
    </ul>
    """
  end

  defp step(assigns) do
    ~H"""
    <li class={step_class(@step, @current_step)}><%= render_slot(@inner_block) %></li>
    """
  end

  defp step_class(step, current_step) do
    if current_step < step do
      "step"
    else
      "step step-secondary"
    end
  end
end
