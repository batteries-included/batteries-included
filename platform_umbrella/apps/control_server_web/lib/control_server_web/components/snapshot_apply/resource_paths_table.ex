defmodule ControlServerWeb.ResourcePathsTable do
  @moduledoc false

  use ControlServerWeb, :html

  import CommonUI.DatetimeDisplay

  defp status_icon(%{is_success: is_success} = assigns) when is_success in ["true", true, :ok] do
    ~H"""
    <div class="flex text-success font-semi-bold">
      <div class="flex-initial">
        Success
      </div>
      <div class="flex-none ml-2">
        <.icon name={:check_circle} class="h-6 w-6" />
      </div>
    </div>
    """
  end

  defp status_icon(%{is_success: _is_success} = assigns) do
    ~H"""
    <div class="flex text-error-dark font-semi-bold">
      <div class="flex-initial">
        Failed
      </div>
      <div class="flex-none ml-2">
        <.icon name={:exclamation_circle} class="h-6 w-6" />
      </div>
    </div>
    """
  end

  def resource_paths_table(assigns) do
    ~H"""
    <.table id="resource-paths" rows={@rows}>
      <:col :let={rp} label="Path"><%= rp.path %></:col>
      <:col :let={rp} label="Successful"><.status_icon is_success={rp.is_success} /></:col>
      <:col :let={rp} label="Result"><%= rp.apply_result %></:col>
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
