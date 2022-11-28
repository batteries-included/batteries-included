defmodule ControlServerWeb.PodsDisplay do
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceURL
  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  defp restart_count(pod) do
    pod
    |> Map.get("status", %{})
    |> Map.get("containerStatuses", [])
    |> Enum.filter(fn cs -> cs != nil end)
    |> Enum.map(fn cs -> Map.get(cs, "restartCount", 0) end)
    |> Enum.sum()
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

  def pods_display(assigns) do
    ~H"""
    <.table id="pod-display-table" rows={@pods}>
      <:col :let={pod} label="Namespace"><%= namespace(pod) %></:col>
      <:col :let={pod} label="Name"><%= name(pod) %></:col>
      <:col :let={pod} label="Status"><%= get_in(pod, ~w(status phase)) %></:col>
      <:col :let={pod} label="Restarts"><%= restart_count(pod) %></:col>
      <:col :let={pod} label="Age"><%= age(pod) %></:col>

      <:action :let={pod}>
        <.link navigate={resource_show_url(pod)} variant="styled">
          Show Pod
        </.link>
      </:action>
    </.table>
    """
  end
end
