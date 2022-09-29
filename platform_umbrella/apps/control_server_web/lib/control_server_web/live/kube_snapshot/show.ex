defmodule ControlServerWeb.Live.KubeSnapshotShow do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.SnapshotApply
  alias Timex

  require Logger

  @impl true
  def mount(params, _session, socket) do
    Logger.debug("Params => #{inspect(params)}")

    {:ok, assign(socket, :snapshot, snapshot(params))}
  end

  def snapshot(params) do
    SnapshotApply.get_preloaded_kube_snapshot!(params["id"])
  end

  defp definition_row(assigns) do
    assigns =
      assign_new(assigns, :wrapper_class, fn -> "py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4" end)

    ~H"""
    <div class={@wrapper_class}>
      <dt class="text-sm font-medium text-gray-500"><%= render_slot(@label) %></dt>
      <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
        <%= render_slot(@inner_block) %>
      </dd>
    </div>
    """
  end

  def display_duration(snapshot) do
    snapshot.updated_at
    |> Timex.diff(snapshot.inserted_at, :duration)
    |> Timex.Format.Duration.Formatters.Humanized.format()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Kube Snapshot Deploy</.title>
      </:title>
      <:left_menu>
        <.magic_menu active="snapshots" />
      </:left_menu>
      <.body_section>
        <dl class="">
          <.definition_row wrapper_class="pb-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4">
            <:label>
              ID
            </:label>
            <%= @snapshot.id %>
          </.definition_row>

          <.definition_row>
            <:label>
              Started
            </:label>
            <%= Timex.format!(@snapshot.inserted_at, "{RFC822z}") %>
          </.definition_row>

          <.definition_row>
            <:label>
              Last Update
            </:label>
            <%= Timex.format!(@snapshot.updated_at, "{RFC822z}") %>
          </.definition_row>

          <.definition_row>
            <:label>
              Elapsed
            </:label>
            <%= display_duration(@snapshot) %>
          </.definition_row>

          <.definition_row>
            <:label>
              Status
            </:label>
            <%= Phoenix.Naming.humanize(@snapshot.status) %>
          </.definition_row>
        </dl>
      </.body_section>
      <.section_title>Path Results</.section_title>
      <.table id="resource-paths" rows={@snapshot.resource_paths}>
        <:col :let={rp} label="Path"><%= rp.path %></:col>
        <:col :let={rp} label="Successful"><%= rp.is_success %></:col>
        <:col :let={rp} label="Result"><%= rp.apply_result %></:col>
      </.table>
    </.layout>
    """
  end
end
