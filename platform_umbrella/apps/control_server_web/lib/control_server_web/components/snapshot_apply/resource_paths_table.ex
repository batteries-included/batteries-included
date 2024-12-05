defmodule ControlServerWeb.ResourcePathsTable do
  @moduledoc false
  use ControlServerWeb, :html

  defp status_icon(%{is_success: is_success} = assigns) when is_success in ["true", true, :ok] do
    ~H"""
    <div class="flex items-center gap-2 font-semibold text-green-500">
      <.icon name={:check_circle} class="size-6" /> Success
    </div>
    """
  end

  defp status_icon(%{is_success: _is_success} = assigns) do
    ~H"""
    <div class="flex items-center gap-2 font-semibold text-red-500">
      <.icon name={:exclamation_circle} class="size-6" /> Failed
    </div>
    """
  end

  def resource_paths_table(assigns) do
    ~H"""
    <.table id="resource-paths" rows={@rows}>
      <:col :let={rp} label="Path">{rp.path}</:col>
      <:col :let={rp} label="Successful"><.status_icon is_success={rp.is_success} /></:col>
      <:col :let={rp} label="Result">{rp.apply_result}</:col>
      <:col :let={rp} label="Hash">
        <.truncate_tooltip value={rp.hash} length={16} />
      </:col>
      <:col :let={rp} label="Updated">
        <.relative_display time={rp.updated_at} />
      </:col>
    </.table>
    """
  end
end
