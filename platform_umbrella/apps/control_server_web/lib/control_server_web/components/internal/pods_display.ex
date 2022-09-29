defmodule ControlServerWeb.PodsDisplay do
  use ControlServerWeb, :component

  import ControlServerWeb.ResourceURL
  import K8s.Resource.FieldAccessors, only: [name: 1, namespace: 1]

  defp inflate_pods(%{pods: pods} = _assigns) do
    pods
    |> Enum.map(&KubeExt.Pods.summarize/1)
    |> Enum.sort_by(
      fn pod ->
        pod
        |> Map.get("status", %{})
        |> Map.get("startTime", "")
      end,
      :desc
    )
  end

  def pods_display(assigns) do
    assigns = assign_new(assigns, :pods, fn -> [] end)
    assigns = assign_new(assigns, :inflated_pods, fn -> inflate_pods(assigns) end)

    ~H"""
    <.table id="pod-display-table" rows={@inflated_pods}>
      <:col :let={pod} label="Namespace"><%= namespace(pod) %></:col>
      <:col :let={pod} label="Name"><%= name(pod) %></:col>
      <:col :let={pod} label="Status"><%= get_in(pod, ~w(status phase)) %></:col>
      <:col :let={pod} label="Restarts"><%= get_in(pod, ~w(summary restartCount)) %></:col>
      <:col :let={pod} label="Age"><%= get_in(pod, ~w(summary fromStart)) %></:col>

      <:action :let={pod}>
        <.link navigate={resource_show_url(pod)} type="styled">
          Show Pod
        </.link>
      </:action>
    </.table>
    """
  end
end
