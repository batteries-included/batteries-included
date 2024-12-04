defmodule ControlServerWeb.Batteries.VictoriaMetricsForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  alias CommonCore.Batteries.VictoriaMetricsConfig
  alias CommonCore.Util.Memory

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

          <.field id="vm_virtual_size">
            <:label>Size</:label>
            <.input
              type="select"
              field={@form[:virtual_size]}
              options={VictoriaMetricsConfig.preset_options_for_select()}
            />
          </.field>

          <.data_list
            :if={@form[:virtual_size].value != "custom"}
            variant="horizontal-bolded"
            class="lg:col-span-2"
            data={[
              {"VMSelect volume size:", Memory.humanize(@form[:vmselect_volume_size].value)},
              {"VMStorage volume size:", Memory.humanize(@form[:vmstorage_volume_size].value)}
            ]}
          />

          <%= if @form[:virtual_size].value == "custom" do %>
            <.fieldset>
              <.field>
                <:label>
                  VMSelect Volume Size · <%= Memory.humanize(@form[:vmselect_volume_size].value) %>
                </:label>
                <:note>You can't reduce this once it has been created.</:note>
                <.input type="number" field={@form[:vmselect_volume_size]} debounce={false} />
              </.field>
            </.fieldset>

            <.fieldset>
              <.field>
                <:label>
                  VMStorage Volume Size · <%= Memory.humanize(@form[:vmstorage_volume_size].value) %>
                </:label>
                <:note>You can't reduce this once it has been created.</:note>
                <.input type="number" field={@form[:vmstorage_volume_size]} debounce={false} />
              </.field>
            </.fieldset>
          <% end %>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
