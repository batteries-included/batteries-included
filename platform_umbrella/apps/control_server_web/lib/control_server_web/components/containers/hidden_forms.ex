defmodule ControlServerWeb.Containers.HiddenForms do
  @moduledoc false

  use ControlServerWeb, :html

  def env_values_hidden_form(assigns) do
    ~H"""
    <.inputs_for :let={env_value} field={@field}>
      <.single_env_value_hidden form={env_value} />
    </.inputs_for>
    """
  end

  def single_env_value_hidden(assigns) do
    ~H"""
    <.input type="hidden" field={@form[:name]} />
    <.input type="hidden" field={@form[:value]} />
    <.input type="hidden" field={@form[:source_type]} />
    <.input type="hidden" field={@form[:source_name]} />
    <.input type="hidden" field={@form[:source_key]} />
    <.input type="hidden" field={@form[:source_optional]} />
    """
  end

  def containers_hidden_form(assigns) do
    ~H"""
    <.inputs_for :let={f_nested} field={@field}>
      <.input type="hidden" field={f_nested[:name]} />
      <.input type="hidden" field={f_nested[:image]} />
      <.input type="hidden" field={f_nested[:path]} />

      <%= if f_nested[:args].value do %>
        <.input
          :for={cmd <- f_nested[:args].value}
          type="hidden"
          name={f_nested[:args].name <> "[]"}
          value={cmd}
        />
      <% end %>

      <.inputs_for :let={env_nested} field={f_nested[:env_values]}>
        <.single_env_value_hidden form={env_nested} />
      </.inputs_for>
    </.inputs_for>
    """
  end

  def ports_hidden_form(assigns) do
    ~H"""
    <.inputs_for :let={port} field={@field}>
      <.single_port_hidden form={port} />
    </.inputs_for>
    """
  end

  def single_port_hidden(assigns) do
    ~H"""
    <.input type="hidden" field={@form[:name]} />
    <.input type="hidden" field={@form[:number]} />
    <.input type="hidden" field={@form[:protocol]} />
    """
  end
end
