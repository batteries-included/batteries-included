defmodule ControlServerWeb.BackendFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Backend.Service
  alias CommonCore.Util.Memory

  attr :class, :any, default: nil
  attr :form, Phoenix.HTML.Form, required: true

  def main_panel(assigns) do
    ~H"""
    <div class={["contents", @class]}>
      <.grid columns={[sm: 1, lg: 2]}>
        <.input label="Name" field={@form[:name]} autofocus placeholder="Name" />

        <.input
          field={@form[:virtual_size]}
          type="select"
          label="Size"
          options={Service.preset_options_for_select()}
        />
      </.grid>

      <.data_list
        :if={@form[:virtual_size].value != "custom"}
        variant="horizontal-bolded"
        class="mt-3 mb-5"
        data={[
          {"Memory limits:", Memory.humanize(@form[:memory_limits].value)},
          {"CPU limits:", @form[:cpu_limits].value}
        ]}
      />
    </div>
    """
  end
end
