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
         |> Timex.parse("{ISO:Extended}") do
      {:ok, start_time} ->
        Timex.from_now(start_time)

      _ ->
        "Unknown"
    end
  end

  defp show_path(nil), do: nil

  defp show_path(pod) do
    namespace = namespace(pod)
    name = name(pod)
    ~p"/kube/pod/#{namespace}/#{name}"
  end

  defp log_path(pod) do
    namespace = namespace(pod)
    name = name(pod)
    ~p"/kube/pod/#{namespace}/#{name}?log=true"
  end

  attr :pods, :list, required: true

  def pods_table(assigns) do
    ~H"""
    <.table :if={@pods != []} rows={@pods} id="pods_table" row_click={&JS.navigate(show_path(&1))}>
      <:col :let={pod} label="Name"><%= name(pod) %></:col>
      <:col :let={pod} label="Namespace"><%= namespace(pod) %></:col>
      <:col :let={pod} label="Status"><%= phase(pod) %></:col>
      <:col :let={pod} label="Restarts"><%= restart_count(pod) %></:col>
      <:col :let={pod} label="Age"><%= age(pod) %></:col>

      <:action :let={pod}>
        <.flex>
          <.action_icon
            to={show_path(pod)}
            icon={:eye}
            tooltip="Show Pod"
            id={"show_pod_" <> to_html_id(pod)}
          />
          <.action_icon
            to={log_path(pod)}
            icon={:document_text}
            tooltip="Logs"
            id={"logs_for_" <> to_html_id(pod)}
          />
        </.flex>
      </:action>
    </.table>

    <.light_text :if={@pods == []}>No pods available</.light_text>
    """
  end
end
