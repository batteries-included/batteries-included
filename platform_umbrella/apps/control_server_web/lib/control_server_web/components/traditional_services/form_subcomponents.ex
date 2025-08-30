defmodule ControlServerWeb.TraditionalFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.TraditionalServices.Service
  alias CommonCore.Util.Memory

  attr :class, :any, default: nil
  attr :with_divider, :boolean, default: true
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
          options={Service.preset_options()}
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

      <%= if @form[:virtual_size].value == "custom" do %>
        <.h3 class="lg:col-span-2">Running Limits</.h3>

        <.fieldset responsive>
          <.field>
            <:label>CPU Requested</:label>
            <.input
              type="select"
              field={@form[:cpu_requested]}
              options={Service.cpu_select_options()}
            />
          </.field>

          <.field>
            <:label>CPU Limits</:label>
            <.input type="select" field={@form[:cpu_limits]} options={Service.cpu_select_options()} />
          </.field>
        </.fieldset>

        <.fieldset responsive>
          <.field>
            <:label>Memory Requested</:label>
            <.input
              type="select"
              field={@form[:memory_requested]}
              options={Service.memory_options() |> Memory.bytes_as_select_options()}
            />
          </.field>

          <.field>
            <:label>Memory Limits</:label>
            <.input
              type="select"
              field={@form[:memory_limits]}
              options={Service.memory_options() |> Memory.bytes_as_select_options()}
            />
          </.field>
        </.fieldset>
      <% end %>

      <.flex
        :if={@with_divider}
        class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker"
      />

      <.grid columns={[sm: 1, lg: 2]} class="items-center">
        <.h5>Number of instances</.h5>
        <.input field={@form[:num_instances]} type="range" min="1" max="5" step="1" />
      </.grid>

      <.input field={@form[:kube_internal]} type="radio" class="mt-4">
        <:option value="true">Internal</:option>
        <:option value="false">External</:option>
      </.input>
    </div>
    """
  end
end
