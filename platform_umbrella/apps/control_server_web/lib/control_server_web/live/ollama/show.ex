defmodule ControlServerWeb.Live.OllamaModelInstanceShow do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ActionsDropdown
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias CommonCore.Util.Memory
  alias ControlServer.Ollama
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :ai)
     |> assign(:page_title, "Ollama Model Instances")}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign_model_instance(id)
     |> assign_main_k8s()
     |> assign_timeline_installed()
     |> maybe_assign_edit_versions()}
  end

  defp assign_model_instance(socket, id) do
    model_instance = Ollama.get_model_instance!(id, preload: [:project])
    assign(socket, model_instance: model_instance)
  end

  defp assign_main_k8s(%{assigns: %{model_instance: %{id: id}}} = socket) do
    assign(socket, k8_services: k8_services(id), k8_pods: k8_pods(id))
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  defp maybe_assign_edit_versions(
         %{assigns: %{model_instance: model_instance, live_action: live_action, timeline_installed: timeline_installed}} =
           socket
       )
       when live_action == :edit_versions and timeline_installed == true do
    assign(socket, :edit_versions, ControlServer.Audit.history(model_instance))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  defp k8_services(id) do
    :service
    |> KubeState.get_all()
    |> Enum.filter(fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_pods(id) do
    :pod
    |> KubeState.get_all()
    |> Enum.filter(fn pg -> id == labeled_owner(pg) end)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    case Ollama.delete_model_instance(socket.assigns.model_instance) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:global_success, "Model successfully deleted")
         |> push_navigate(to: ~p"/model_instances")}

      _ ->
        {:noreply, put_flash(socket, :global_error, "Could not delete model")}
    end
  end

  defp show_url(model_instance), do: ~p"/model_instances/#{model_instance}/show"
  defp pods_url(model_instance), do: ~p"/model_instances/#{model_instance}/pods"
  defp services_url(model_instance), do: ~p"/model_instances/#{model_instance}/services"
  defp edit_url(model_instance), do: ~p"/model_instances/#{model_instance}/edit"
  defp edit_versions_url(model_instance), do: ~p"/model_instances/#{model_instance}/edit_versions"

  defp header(assigns) do
    ~H"""
    <.page_header title={"Ollama Model: #{@model_instance.name}"} back_link={@back_link}>
      <:menu>
        <.badge :if={@model_instance.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@model_instance.project_id}/show"}>
            {@model_instance.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.actions_dropdown>
          <.dropdown_link navigate={edit_url(@model_instance)} icon={:pencil}>
            Edit Model
          </.dropdown_link>

          <.dropdown_button
            class="w-full"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the #{@model_instance.name} model?"}
          >
            Delete Model
          </.dropdown_button>
        </.actions_dropdown>
      </.flex>
    </.page_header>
    """
  end

  defp links_panel(assigns) do
    ~H"""
    <.panel variant="gray">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :show} patch={show_url(@model_instance)}>Overview</:tab>
        <:tab selected={@live_action == :pods} patch={pods_url(@model_instance)}>Pods</:tab>
        <:tab selected={@live_action == :services} patch={services_url(@model_instance)}>
          Services
        </:tab>
        <:tab
          :if={@timeline_installed}
          selected={@live_action == :edit_versions}
          patch={edit_versions_url(@model_instance)}
        >
          Edit Versions
        </:tab>
      </.tab_bar>
    </.panel>
    """
  end

  def main_page(assigns) do
    ~H"""
    <.header model_instance={@model_instance} back_link={~p"/model_instances"} />
    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Details" class="lg:col-span-3 lg:row-span-2">
        <.data_list>
          <:item title="Model">
            {@model_instance.model}
          </:item>
          <:item title="Instances">
            {@model_instance.num_instances}
          </:item>
          <:item :if={@model_instance.memory_limits} title="Memory Limits">
            {Memory.humanize(@model_instance.memory_limits)}
          </:item>
        </.data_list>
      </.panel>
      <.links_panel
        timeline_installed={@timeline_installed}
        model_instance={@model_instance}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp pods_page(assigns) do
    ~H"""
    <.header model_instance={@model_instance} back_link={show_url(@model_instance)} />
    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Pods" class="lg:col-span-3 lg:row-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>
      <.links_panel
        timeline_installed={@timeline_installed}
        model_instance={@model_instance}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp services_page(assigns) do
    ~H"""
    <.header model_instance={@model_instance} back_link={show_url(@model_instance)} />
    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Services" class="lg:col-span-3 lg:row-span-2">
        <.services_table services={@k8_services} />
      </.panel>
      <.links_panel
        timeline_installed={@timeline_installed}
        model_instance={@model_instance}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.header model_instance={@model_instance} back_link={show_url(@model_instance)} />
    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Edit History" class="lg:col-span-3 lg:row-span-2">
        <.edit_versions_table rows={@edit_versions} abridged />
      </.panel>
      <.links_panel
        timeline_installed={@timeline_installed}
        model_instance={@model_instance}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          model_instance={@model_instance}
          timeline_installed={@timeline_installed}
          live_action={@live_action}
        />
      <% :pods -> %>
        <.pods_page
          model_instance={@model_instance}
          timeline_installed={@timeline_installed}
          live_action={@live_action}
          k8_pods={@k8_pods}
        />
      <% :services -> %>
        <.services_page
          model_instance={@model_instance}
          timeline_installed={@timeline_installed}
          live_action={@live_action}
          k8_services={@k8_services}
        />
      <% :edit_versions -> %>
        <.edit_versions_page
          model_instance={@model_instance}
          timeline_installed={@timeline_installed}
          live_action={@live_action}
          edit_versions={@edit_versions}
        />
    <% end %>
    """
  end
end
