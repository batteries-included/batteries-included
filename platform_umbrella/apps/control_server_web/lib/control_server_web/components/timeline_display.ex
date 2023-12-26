defmodule ControlServerWeb.TimelineDisplay do
  @moduledoc false
  use ControlServerWeb, :html

  import ControlServerWeb.ResourceHTMLHelper

  alias CommonCore.Timeline.BatteryInstall
  alias CommonCore.Timeline.Kube
  alias CommonCore.Timeline.NamedDatabase

  slot :inner_block, required: true

  def feed_timeline(assigns) do
    ~H"""
    <div class="container mx-auto w-full h-full">
      <div class="relative wrap overflow-hidden p-10 h-full">
        <div
          class="border-2-2 absolute border-opacity-20 border-gray-700 h-full border"
          style="left: 50%"
        >
        </div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr :timestamp, :any, default: nil
  attr :payload, :any, default: nil
  attr :title, :string, default: ""
  attr :index, :integer, default: 0
  slot :inner_block

  def timeline_item(%{payload: %NamedDatabase{}} = assigns) do
    ~H"""
    <.timeline_item timestamp={display_when(@timestamp)} index={@index}>
      <%= human_name(@payload.action) %> on <%= human_name(@payload.type) %> named <%= @payload.name %>
    </.timeline_item>
    """
  end

  def timeline_item(%{payload: %Kube{action: :add}} = assigns) do
    ~H"""
    <.timeline_item
      timestamp={display_when(@timestamp)}
      index={@index}
      title="New Kubernetes Resource"
    >
      The Control Server detected a new <%= human_name(@payload.type) %> resouce named <%= @payload.name %> added in
      the <%= @payload.namespace %> namespace. <br />
      If that resource has not since been removed you can find a status page
      <.a navigate={resource_path(@payload)} variant="styled">here</.a>
    </.timeline_item>
    """
  end

  def timeline_item(%{payload: %Kube{action: :update, type: :pod, computed_status: :ready}} = assigns) do
    ~H"""
    <.timeline_item
      timestamp={display_when(@timestamp)}
      index={@index}
      title="Kubernetes Resource Ready"
    >
      A <%= human_name(@payload.type) %> named
      <.a navigate={resource_path(@payload)} variant="styled"><%= @payload.name %></.a>
      in the <%= @payload.namespace %> namespace became Ready.
    </.timeline_item>
    """
  end

  def timeline_item(%{payload: %Kube{action: :delete}} = assigns) do
    ~H"""
    <.timeline_item
      timestamp={display_when(@timestamp)}
      index={@index}
      title="Removed Kubernetes Resource"
    >
      A previously existing <%= human_name(@payload.type) %> named <%= @payload.name %> in the <%= @payload.namespace %> namespace was removed.
    </.timeline_item>
    """
  end

  def timeline_item(%{payload: %BatteryInstall{}} = assigns) do
    ~H"""
    <.timeline_item timestamp={display_when(@timestamp)} index={@index} title="New Battery Installed">
      Either you or the system installed a new battery of type <%= human_name(@payload.type) %>
    </.timeline_item>
    """
  end

  def timeline_item(assigns) do
    ~H"""
    <div class={[timeline_item_container_class(@index)]}>
      <div class="order-1 w-5/12"></div>
      <div class="z-20 flex items-center order-1 bg-pink-500 shadow-xl w-8 h-8 rounded-full">
        <h1 class="mx-auto font-semibold text-lg text-white"><%= @index %></h1>
      </div>
      <div class="order-1 bg-white rounded-lg shadow-xl w-5/12 px-6 py-4">
        <h3 class="font-bold text-xl"><%= @title %></h3>
        <h3 class="text-astral-500 text-sm mb-3"><%= @timestamp %></h3>
        <p class="text-base leading-snug tracking-wide text-opacity-100">
          <%= render_slot(@inner_block) %>
        </p>
      </div>
    </div>
    """
  end

  defp timeline_item_container_class(index) when is_binary(index),
    do: timeline_item_container_class(String.to_integer(index))

  defp timeline_item_container_class(index) when is_integer(index),
    do: timeline_item_container_class(Integer.mod(index, 2) == 0)

  defp timeline_item_container_class(true), do: "mb-8 flex justify-between items-center w-full right-timeline"

  defp timeline_item_container_class(false),
    do: "mb-8 flex justify-between flex-row-reverse items-center w-full left-timeline"

  defp display_when(nil), do: "Unknown Time"
  defp display_when(datetime), do: Timex.from_now(datetime)

  defp human_name(atom_var) do
    atom_var |> to_string() |> Phoenix.Naming.humanize() |> titlecase()
  end

  defp titlecase(var) do
    var
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
