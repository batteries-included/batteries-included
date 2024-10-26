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
        <.fieldset>
          <.image><%= @form[:operator_image].value %></.image>

          <.image_version
            field={@form[:operator_image_tag_override]}
            image_id={:vm_operator}
            label="Operator Version"
          />
        </.fieldset>
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.field>
            <:label>Cookie Secret</:label>
            <.input type="password" field={@form[:cookie_secret]} disabled={@action != :new} />
          </.field>

          <.field>
            <:label>Replication Factor</:label>
            <.input type="number" field={@form[:replication_factor]} />
          </.field>

          <.field>
            <:label>Insert Replicas</:label>
            <.input type="number" field={@form[:vminsert_replicas]} />
          </.field>

          <.field>
            <:label>Select Replicas</:label>
            <.input type="number" field={@form[:vmselect_replicas]} />
          </.field>

          <.field>
            <:label>Storage Replicas</:label>
            <.input type="number" field={@form[:vmstorage_replicas]} />
          </.field>

          <.field>
            <:label>Select Volume Size</:label>
            <.input field={@form[:vmselect_volume_size]} />
          </.field>

          <.field>
            <:label>Storage Volume Size</:label>
            <.input field={@form[:vmstorage_volume_size]} />
          </.field>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
