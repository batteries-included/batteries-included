defmodule ControlServerWeb.FerretDBFormSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.FerretDB.FerretService
  alias CommonCore.Util.Memory

  attr :class, :any, default: nil
  attr :action, :atom, default: nil
  attr :form, Phoenix.HTML.Form, required: true
  attr :pg_clusters, :list

  def size_form(assigns) do
    ~H"""
    <div class={["contents", @class]}>
      <.grid columns={[sm: 1, lg: 2]}>
        <.input field={@form[:name]} label="Name" />
        <.input
          :if={assigns[:pg_clusters]}
          field={@form[:postgres_cluster_id]}
          label="Postgres Cluster"
          type="select"
          placeholder="Choose a postgres cluster"
          options={Enum.map(@pg_clusters, &{&1.name, &1.id})}
        />
        <.input
          field={@form[:virtual_size]}
          type="select"
          label="Size"
          placeholder="Choose a size"
          options={FerretService.preset_options()}
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

      <.grid :if={@form[:virtual_size].value == "custom"} columns={[sm: 1, md: 2, xl: 4]}>
        <.input field={@form[:cpu_requested]} label="Cpu requested" />
        <.input field={@form[:cpu_limits]} label="Cpu limits" />
        <.input field={@form[:memory_requested]} label="Memory requested" />
        <.input field={@form[:memory_limits]} label="Memory limits" />
      </.grid>
    </div>
    """
  end
end
