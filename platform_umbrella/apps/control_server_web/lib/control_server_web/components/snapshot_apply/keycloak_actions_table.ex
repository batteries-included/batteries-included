defmodule ControlServerWeb.KeycloakActionsTable do
  @moduledoc false
  use ControlServerWeb, :html

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

  def keycloak_action_table(assigns) do
    ~H"""
    <.table id="actions" rows={@rows}>
      <:col :let={act} label="Realm"><%= act.realm %></:col>
      <:col :let={act} label="Action"><%= act.action %></:col>
      <:col :let={act} label="Successful"><.status_icon is_success={act.is_success} /></:col>
      <:col :let={act} label="Result"><%= act.apply_result %></:col>
      <:col :let={act} label="Updated">
        <.relative_display time={act.updated_at} />
      </:col>
    </.table>
    """
  end
end
