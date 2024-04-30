defmodule ControlServerWeb.ContentAddressable.ResourceTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :resources, :list, required: true

  def documents_table(%{} = assigns) do
    ~H"""
    <.table id="resources-table" rows={@resources || []}>
      <:col :let={resource} label="Hash"><%= resource.hash %></:col>
      <:col :let={resource} label="Size"><%= approx_size(resource) %></:col>
      <:col :let={resource} label="Inserted At">
        <%= CommonCore.Util.Time.format(resource.inserted_at) %>
      </:col>
    </.table>
    """
  end

  defp approx_size(resource) do
    resource.value
    |> Jason.encode!()
    |> String.length()
  end
end
