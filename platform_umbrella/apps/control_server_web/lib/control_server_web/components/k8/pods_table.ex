defmodule ControlServerWeb.PodsTable do
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

  attr :id, :string, default: "pods-table"
  attr :pods, :list, required: true

  def pods_table(assigns) do
    ~H"""
    <.table rows={@pods} id={@id}>
      <:col :let={pod} label="Name"><%= name(pod) %></:col>
      <:col :let={pod} label="Namespace"><%= namespace(pod) %></:col>
      <:col :let={pod} label="Status"><%= get_in(pod, ~w(status phase)) %></:col>
      <:col :let={pod} label="Restarts"><%= restart_count(pod) %></:col>
      <:col :let={pod} label="Age"><%= age(pod) %></:col>

      <:action :let={pod}>
        <.a navigate={resource_show_url(pod)} variant="styled">
          Show Pod
        </.a>
        <.a class="ml-4" navigate={resource_show_url(pod, %{"log" => true})}>
          Logs
        </.a>
      </:action>
    </.table>
    """
  end
end
