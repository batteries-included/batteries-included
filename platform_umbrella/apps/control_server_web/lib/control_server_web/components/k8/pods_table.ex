defmodule ControlServerWeb.PodsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  defp restart_count(pod) do
    pod
    |> container_statuses()
    |> Enum.filter(& &1)
    |> Enum.reduce(0, fn cs, acc -> acc + Map.get(cs, "restartCount", 0) end)
  end

  defp age(pod) do
    case pod
         |> Map.get("status", %{})
         |> Map.get("startTime", "")
         |> DateTime.from_iso8601() do
      {:ok, start_time, _} ->
        CommonCore.Util.Time.from_now(start_time)

      _ ->
        "Unknown"
    end
  end

  attr :pods, :list, required: true

  def pods_table(assigns) do
    ~H"""
    <.table rows={@pods || []} id="pods_table" row_click={&JS.navigate(resource_path(&1))}>
      <:col :let={pod} label="Name">{name(pod)}</:col>
      <:col :let={pod} label="Namespace">{namespace(pod)}</:col>
      <:col :let={pod} label="Status">{phase(pod)}</:col>
      <:col :let={pod} label="Restarts">{restart_count(pod)}</:col>
      <:col :let={pod} label="Age">{age(pod)}</:col>

      <:action :let={pod}>
        <.flex>
          <.button
            variant="minimal"
            link={resource_path(pod, :logs)}
            icon={:document_text}
            id={"logs_for_" <> to_html_id(pod)}
          />

          <.tooltip target_id={"logs_for_" <> to_html_id(pod)}>
            Logs
          </.tooltip>

          <.button
            variant="minimal"
            link={resource_path(pod)}
            icon={:eye}
            id={"pod_show_link_" <> to_html_id(pod)}
          />
          <.tooltip target_id={"pod_show_link_" <> to_html_id(pod)}>
            Show Pod
          </.tooltip>
        </.flex>
      </:action>
    </.table>

    <.light_text :if={@pods == []}>No pods available</.light_text>
    """
  end
end
