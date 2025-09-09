defmodule ControlServerWeb.Batteries.VictoriaMetricsForm do
  @moduledoc false

  use ControlServerWeb, :live_component

  import ControlServerWeb.BatteriesFormSubcomponents

  alias CommonCore.Batteries.VictoriaMetricsConfig
  alias CommonCore.Util.Memory

  def handle_event(
        "change_storage_size_range",
        %{"victoria_metrics_config" => %{"virtual_vmselect_storage_size_range" => size}},
        socket
      ),
      do: update_volume_size(:vmselect_volume_size, size, socket)

  def handle_event(
        "change_storage_size_range",
        %{"battery_config" => %{"virtual_vmselect_storage_size_range" => size}},
        socket
      ),
      do: update_volume_size(:vmselect_volume_size, size, socket)

  def handle_event(
        "change_storage_size_range",
        %{"victoria_metrics_config" => %{"virtual_vmstorage_storage_size_range" => size}},
        socket
      ),
      do: update_volume_size(:vmstorage_volume_size, size, socket)

  def handle_event(
        "change_storage_size_range",
        %{"battery_config" => %{"virtual_vmstorage_storage_size_range" => size}},
        socket
      ),
      do: update_volume_size(:vmstorage_volume_size, size, socket)

  defp update_volume_size(field, size, %{assigns: %{form: %{name: name, source: source}}} = socket) do
    old_size = Map.get(source.data, field, 0) || 0

    changeset =
      source
      |> VictoriaMetricsConfig.put_volume_size(field, size, old_size)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: name))}
  end

  def render(assigns) do
    assigns =
      assign(assigns, :ticks, VictoriaMetricsConfig.volume_range_ticks())

    ~H"""
    <div class="contents">
      <.panel title="Description">
        {@battery.description}
      </.panel>

      <.panel title="Image">
        <.fieldset>
          <.image>{@form[:operator_image].value}</.image>

          <.image_version
            field={@form[:operator_image_tag_override]}
            image_id={:vm_operator}
            label="Operator Version"
          />
        </.fieldset>
      </.panel>

      <.panel title="Configuration">
        <.fieldset>
          <.image_version
            field={@form[:cluster_image_tag_override]}
            image_id={:vm_insert}
            label="Cluster Image Tag"
          />

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
              options={VictoriaMetricsConfig.preset_options()}
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
                  VMSelect Volume Size · {Memory.humanize(@form[:vmselect_volume_size].value)}
                </:label>
                <:note>You can't reduce this once it has been created.</:note>
                <.input type="number" field={@form[:vmselect_volume_size]} debounce={false} />
              </.field>
              <.field>
                <.input
                  id="vmselect_virtual_volume_size"
                  type="range"
                  field={@form[:virtual_vmselect_storage_size_range]}
                  show_value={false}
                  min={@ticks |> Memory.min_range_value()}
                  max={@ticks |> Memory.max_range_value()}
                  ticks={@ticks}
                  tick_target={@myself}
                  tick_click="change_storage_size_range"
                  phx-change="change_storage_size_range"
                  phx-target={@myself}
                  lower_boundary={
                    @form.data.vmselect_volume_size |> Memory.bytes_to_range_value(@ticks)
                  }
                  class="px-5 self-center"
                />
              </.field>
            </.fieldset>

            <.fieldset>
              <.field>
                <:label>
                  VMStorage Volume Size · {Memory.humanize(@form[:vmstorage_volume_size].value)}
                </:label>
                <:note>You can't reduce this once it has been created.</:note>
                <.input type="number" field={@form[:vmstorage_volume_size]} debounce={false} />
              </.field>
              <.field>
                <.input
                  id="vmstorage_virtual_volume_size"
                  type="range"
                  field={@form[:virtual_vmstorage_storage_size_range]}
                  show_value={false}
                  min={@ticks |> Memory.min_range_value()}
                  max={@ticks |> Memory.max_range_value()}
                  ticks={@ticks}
                  tick_target={@myself}
                  tick_click="change_storage_size_range"
                  phx-change="change_storage_size_range"
                  phx-target={@myself}
                  lower_boundary={
                    @form.data.vmstorage_volume_size |> Memory.bytes_to_range_value(@ticks)
                  }
                  class="px-5 self-center"
                />
              </.field>
            </.fieldset>
          <% end %>
        </.fieldset>
      </.panel>
    </div>
    """
  end
end
