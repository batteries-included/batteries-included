defmodule ControlServerWeb.ModelInstancesTable do
  @moduledoc false

  use ControlServerWeb, :html

  alias CommonCore.Util.Memory

  attr :rows, :list, default: []
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false

  def model_instances_table(assigns) do
    ~H"""
    <.table
      id="model-instances-display-table"
      variant={@meta && ~c"paginated"}
      rows={@rows}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={model_instance} :if={!@abridged} field={:id} label="ID">
        <%= model_instance.id %>
      </:col>
      <:col :let={model_instance} field={:name} label="Name"><%= model_instance.name %></:col>
      <:col :let={model_instance} field={:model} label="Model"><%= model_instance.model %></:col>
      <:col :let={model_instance} :if={!@abridged} field={:memory_limits} label="Memory Limits">
        <%= Memory.humanize(model_instance.memory_limits) %>
      </:col>

      <:action :let={model_instance}>
        <.flex class="justify-items-center align-middle">
          <.button
            variant="minimal"
            link={edit_url(model_instance)}
            icon={:pencil}
            id={"edit_model_instance_" <> model_instance.id}
          />

          <.tooltip target_id={"edit_model_instances" <> model_instance.id}>
            Edit Ollama Model
          </.tooltip>

          <.button
            variant="minimal"
            link={show_url(model_instance)}
            icon={:eye}
            id={"model_instance_show_link_" <> model_instance.id}
            class="sm:hidden"
          />
          <.tooltip target_id={"model_instance_show_link_" <> model_instance.id}>
            Show Ollama Model
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(model_instance), do: ~p"/model_instances/#{model_instance}/show"
  defp edit_url(model_instance), do: ~p"/model_instances/#{model_instance}/edit"
end
