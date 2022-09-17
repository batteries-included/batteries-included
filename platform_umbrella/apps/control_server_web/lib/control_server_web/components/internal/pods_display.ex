defmodule ControlServerWeb.PodsDisplay do
  use ControlServerWeb, :component

  import CommonUI.Table
  import ControlServerWeb.ResourceURL

  def inflate_pods(%{pods: pods} = _assigns) do
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
    <.table>
      <.thead>
        <.tr>
          <.th>
            Namespace
          </.th>
          <.th>
            Name
          </.th>
          <.th>
            Status
          </.th>
          <.th>Restarts</.th>
          <.th>
            Age
          </.th>
        </.tr>
      </.thead>
      <.tbody>
        <%= for pod <- @inflated_pods do %>
          <.pod_row pod={pod} />
        <% end %>
      </.tbody>
    </.table>
    """
  end

  defp pod_row(assigns) do
    ~H"""
    <.tr>
      <.td>
        <%= @pod["metadata"]["namespace"] %>
      </.td>
      <.td>
        <.link to={resource_show_url(@pod)}>
          <%= @pod["metadata"]["name"] %>
        </.link>
      </.td>
      <.td>
        <%= @pod["status"]["phase"] %>
      </.td>
      <.td>
        <%= @pod["summary"]["restartCount"] %>
      </.td>
      <.td>
        <%= @pod["summary"]["fromStart"] %>
      </.td>
    </.tr>
    """
  end
end
