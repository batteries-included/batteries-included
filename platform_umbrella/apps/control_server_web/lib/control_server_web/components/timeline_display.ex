defmodule ControlServerWeb.TimelineDisplay do
  use ControlServerWeb, :html

  alias ControlServer.Timeline.BatteryInstall
  alias ControlServer.Timeline.Kube
  alias ControlServer.Timeline.NamedDatabase

  slot :inner_block, required: true

  def feed_timeline(assigns) do
    ~H"""
    <div class="flow-root">
      <ul role="list" class="-mb-8">
        <%= render_slot(@inner_block) %>
      </ul>
    </div>
    """
  end

  attr :user_id, :string, default: nil
  attr :user_name, :string, default: "System User"

  attr :timestamp, :any, default: nil
  attr :payload, :any, default: nil
  attr :action, :string, default: "updated"
  attr :display_line, :boolean, default: true
  slot :image
  slot :inner_block

  def timeline_item(%{payload: %NamedDatabase{}} = assigns) do
    ~H"""
    <.timeline_item
      timestamp={display_when(@timestamp)}
      action={@payload.action}
      user_name="You"
      user_id="kubernetes"
    >
      <:image>
        <.timeline_image src={icon_url("YOU")} />
      </:image>
      <p>
        <%= human_name(@payload.action) %> on <%= human_name(@payload.type) %> named <%= @payload.name %>
      </p>
    </.timeline_item>
    """
  end

  def timeline_item(%{payload: %Kube{action: :add}} = assigns) do
    ~H"""
    <.timeline_item
      timestamp={display_when(@timestamp)}
      action="add"
      user_name="Kubernetes"
      user_id="kubernetes"
    >
      <:image>
        <.timeline_image src={icon_url("kubernetes")} />
      </:image>
      <p>
        New kubernetes <%= @payload.type %> resouce named <%= @payload.name %> added in <%= @payload.namespace %>
      </p>
    </.timeline_item>
    """
  end

  def timeline_item(%{payload: %Kube{action: :delete}} = assigns) do
    ~H"""
    <.timeline_item
      timestamp={display_when(@timestamp)}
      action="delete"
      user_name="Kubernetes"
      user_id="kubernetes"
    >
      <:image>
        <.timeline_image src={icon_url("Kubernetes")} />
      </:image>
      <p>Removed <%= @payload.type %>/<%= @payload.name %> in <%= @payload.namespace %></p>
    </.timeline_item>
    """
  end

  def timeline_item(%{payload: %BatteryInstall{}} = assigns) do
    ~H"""
    <.timeline_item timestamp={display_when(@timestamp)} action="battery install" user_name="You">
      <:image>
        <.timeline_image src={icon_url("YOU")} />
      </:image>
      <p>The new battery <%= @payload.type %> was enabled.</p>
    </.timeline_item>
    """
  end

  def timeline_item(assigns) do
    ~H"""
    <li>
      <div class="relative pb-8">
        <span
          :if={@display_line}
          class="absolute top-5 left-5 -ml-px h-full w-0.5 bg-gray-200"
          aria-hidden="true"
        >
        </span>
        <div class="relative flex items-start space-x-3">
          <div :if={@image != nil} class="relative">
            <%= render_slot(@image) %>
          </div>
          <div class="min-w-0 flex-1">
            <div>
              <div class="text-sm text-lg font-medium text-gray-900">
                <%= @user_name %>
              </div>
              <p class="mt-0.5 text-sm text-gray-500">
                <%= @action %> @ <%= @timestamp %>
              </p>
            </div>
            <div :if={@inner_block != nil} class="mt-2 text-sm">
              <%= render_slot(@inner_block) %>
            </div>
          </div>
        </div>
      </div>
    </li>
    """
  end

  attr :src, :string, required: true

  defp timeline_image(assigns) do
    ~H"""
    <img class="flex h-10 w-10 items-center justify-center rounded-full" src={@src} alt="" />
    """
  end

  defp icon_url(nil), do: icon_url("system_user")

  defp icon_url(user_id) do
    encoded_who = URI.encode(user_id)
    "https://robohash.org/#{encoded_who}.png?set=set1"
  end

  defp display_when(nil), do: "Unknown Time"
  defp display_when(datetime), do: Timex.from_now(datetime)

  defp human_name(atom_var) do
    atom_var |> to_string() |> Phoenix.Naming.humanize()
  end
end
