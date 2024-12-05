defmodule ControlServerWeb.ContentAddressable.DocumentsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :rows, :list, default: []
  attr :meta, :map, default: nil

  def documents_table(%{} = assigns) do
    ~H"""
    <.table
      id="documents-table"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/content_addressable"}
    >
      <:col :let={resource} field={:hash} label="Hash">{resource.hash}</:col>
      <:col :let={resource} field={:value} label="Size">{approx_size(resource)}</:col>
      <:col :let={resource} field={:inserted_at} label="Inserted At">
        {CommonCore.Util.Time.format(resource.inserted_at)}
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
