defmodule ControlServerWeb.RedisFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Redis.FailoverCluster
  alias CommonCore.Util.Memory

  attr :class, :any, default: nil
  attr :action, :atom, default: nil
  attr :form, Phoenix.HTML.Form, required: true

  def size_form(assigns) do
    ~H"""
    <div class={["contents", @class]}>
      <.grid columns={[sm: 1, lg: 2]} class="items-center">
        <.input field={@form[:name]} label="Name" disabled={@action == :edit} />

        <.input
          field={@form[:virtual_size]}
          type="select"
          label="Size"
          placeholder="Choose a size"
          options={FailoverCluster.preset_options_for_select()}
        />
      </.grid>

      <.data_list
        :if={@form[:virtual_size].value != "custom"}
        variant="horizontal-bolded"
        class="mt-3 mb-5"
        data={[
          {"Memory limits:", @form[:memory_limits].value |> Memory.format_bytes(true)},
          {"CPU limits:", @form[:cpu_limits].value}
        ]}
      />

      <.flex :if={@form[:virtual_size].value == "custom"} column class="py-4">
        <.h3>Running Limits</.h3>

        <.grid columns={[sm: 1, md: 2, xl: 4]}>
          <.input field={@form[:cpu_requested]} label="CPU Requested" />
          <.input field={@form[:cpu_limits]} label="CPU Limits" />
          <.input field={@form[:memory_requested]} label="Memory Requested" />
          <.input field={@form[:memory_limits]} label="Memory Limits" />
        </.grid>
      </.flex>
    </div>
    """
  end
end
