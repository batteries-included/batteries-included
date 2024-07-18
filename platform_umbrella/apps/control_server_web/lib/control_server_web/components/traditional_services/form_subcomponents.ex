defmodule ControlServerWeb.TraditionalFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.TraditionalServices.Service
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

      <.flex class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker" />

      <.grid columns={[sm: 1, lg: 2]} class="items-center">
        <.h5>Number of instances</.h5>
        <.input field={@form[:num_instances]} type="range" min="1" max="5" step="1" />
      </.grid>
    </div>
    """
  end
end
