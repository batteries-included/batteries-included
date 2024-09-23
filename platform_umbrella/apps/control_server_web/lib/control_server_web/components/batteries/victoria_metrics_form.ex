defmodule ControlServerWeb.Batteries.VictoriaMetricsForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.panel title="Description">
        <%= @battery.description %>
      </.panel>

      <.panel title="Image">
        <.simple_form variant="nested">
          <.image><%= @form[:operator_image].value %></.image>

          <.image_version
            field={@form[:operator_image_tag_override]}
            image_id={:vm_operator}
            label="Operator Version"
          />
        </.simple_form>
      </.panel>

      <.panel title="Configuration">
        <.simple_form variant="nested">
          <.input
            field={@form[:cookie_secret]}
            type="password"
            label="Cookie Secret"
            disabled={@action != :new}
          />
          <.input field={@form[:replication_factor]} type="number" label="Replication Factor" />
          <.input field={@form[:vminsert_replicas]} type="number" label="Insert Replicas" />
          <.input field={@form[:vmselect_replicas]} type="number" label="Select Replicas" />
          <.input field={@form[:vmstorage_replicas]} type="number" label="Storage Replicas" />
          <.input field={@form[:vmselect_volume_size]} label="Select Volume Size" />
          <.input field={@form[:vmstorage_volume_size]} label="Storage Volume Size" />
        </.simple_form>
      </.panel>
    </div>
    """
  end
end
