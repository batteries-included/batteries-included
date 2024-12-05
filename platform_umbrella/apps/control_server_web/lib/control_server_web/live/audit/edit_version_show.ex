defmodule ControlServerWeb.Live.EditVersionShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Postgres.PGUser
  alias Phoenix.Naming

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _, socket) do
    {:ok, socket |> assign_edit_version(id) |> assign_page_title()}
  end

  defp assign_edit_version(socket, id) do
    assign(socket, :edit_version, ControlServer.Audit.get_edit_version!(id))
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Edit Version")
  end

  defp entity_history_url(%{entity_schema: schema, entity_id: entity_id} = _edit_version) do
    case schema do
      CommonCore.Postgres.Cluster ->
        ~p"/postgres/#{entity_id}/edit_versions"

      CommonCore.Knative.Service ->
        ~p"/knative/services/#{entity_id}/edit_versions"

      CommonCore.FerretDB.FerretService ->
        ~p"/ferretdb/#{entity_id}/edit_versions"

      _ ->
        nil
    end
  end

  defp patch_value(%{value: value} = assigns) when is_list(value) do
    ~H"""
    <.flex column>
      <.patch_value :for={v <- @value} value={v} />
    </.flex>
    """
  end

  defp patch_value(%{value: %DateTime{} = _value} = assigns) do
    ~H"""
    <.relative_display time={@value} />
    """
  end

  defp patch_value(%{value: %PGUser{} = _value} = assigns) do
    ~H"""
    <.patch_value value={sanitize_pg_user(@value)} />
    """
  end

  defp patch_value(%{value: value} = assigns) when is_struct(value) do
    ~H"""
    <.patch_value value={Map.from_struct(@value)} />
    """
  end

  defp patch_value(%{value: value} = assigns) when is_map(value) do
    ~H"""
    <.data_list>
      <:item :for={{k, v} <- @value} title={k}>
        <.patch_value value={v} />
      </:item>
    </.data_list>
    """
  end

  defp patch_value(%{value: {:primitive_change, from, to}} = assigns) do
    assigns = assigns |> assign(:from, from) |> assign(:to, to)

    ~H"""
    <.patch_value from={@from} to={@to} />
    """
  end

  defp patch_value(%{value: {:changed, inner_value}} = assigns) do
    assigns = assign(assigns, :inner_value, inner_value)

    ~H"""
    <.patch_value value={@inner_value} />
    """
  end

  defp patch_value(%{value: {:added_to_list, _idx, inner_value}} = assigns) do
    assigns = assign(assigns, :inner_value, inner_value)

    ~H"""
    <.patch_value value={@inner_value} />
    """
  end

  defp patch_value(%{from: _from, to: _to} = assigns) do
    ~H"""
    <.flex class="align-middle items-center">
      <.patch_value value={@from} />
      <.icon name={:arrow_right} class="h-4" />
      <.patch_value value={@to} />
    </.flex>
    """
  end

  defp patch_value(%{value: value} = assigns) when is_tuple(value) do
    ~H"""
    <.flex>
      <.patch_value :for={v <- Tuple.to_list(@value)} value={v} />
    </.flex>
    """
  end

  defp patch_value(%{value: _} = assigns) do
    ~H"""
    <div class="text-gray dark:text-gray-darker">{@value}</div>
    """
  end

  defp sanitize_pg_user(%PGUser{} = user) do
    default = "**** REDACTED ****"

    user |> Map.from_struct() |> Map.update(:password, default, fn _ -> default end)
  end

  defp field_action(_action, [{:added_to_list, _, _}] = _change) do
    "Added To List"
  end

  defp field_action(action, _change) do
    Naming.humanize(action)
  end

  defp patch_table(assigns) do
    ~H"""
    <.table
      id="version-patch-table"
      rows={
        @edit_version.patch
        |> Enum.reject(fn {field, _v} -> to_string(field) |> String.starts_with?("virtual") end)
      }
    >
      <:col :let={{field, _change}} label="Field">
        {field}
      </:col>
      <:col :let={{_field, {field_action, value}}} label="Field Action">
        {field_action(field_action, value)}
      </:col>
      <:col :let={{_field, {_field_action, value}}} label="Change">
        <.patch_value value={value} />
      </:col>
    </.table>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={entity_history_url(@edit_version)}>
      <.badge>
        <:item label="Action">{@edit_version.action}</:item>
        <:item label="Recorded At">
          <.relative_display time={@edit_version.recorded_at} />
        </:item>
      </.badge>
    </.page_header>
    <.flex column>
      <.panel title="Patch">
        <.patch_table edit_version={@edit_version} />
      </.panel>
    </.flex>
    """
  end
end
