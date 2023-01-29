defmodule ControlServerWeb.Live.Knative.FormComponent do
  use ControlServerWeb, :live_component

  import ControlServerWeb.KnativeFormSubcomponents
  import KubeServices.SystemState.SummaryHosts

  alias CommonCore.Knative.Container
  alias Ecto.Changeset
  alias CommonCore.Knative.EnvValue
  alias ControlServer.Knative
  alias CommonCore.Knative.Service

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "service:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  def assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset)
  end

  def assign_url(socket, url) do
    assign(socket, url: url)
  end

  @impl Phoenix.LiveComponent
  def update(%{service: service} = assigns, socket) do
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_url("http://#{knative_host(service)}")
     |> assign_changeset(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("add:env_value", _params, %{assigns: %{changeset: changeset}} = socket) do
    env_values = Changeset.get_field(changeset, :env_values, []) ++ [%EnvValue{}]
    final_changeset = Changeset.put_embed(changeset, :env_values, env_values)
    {:noreply, assign_changeset(socket, final_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "del:env_value",
        %{"idx" => idx} = _params,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    env_values =
      changeset |> Changeset.get_field(:env_values, []) |> List.delete_at(String.to_integer(idx))

    final_changeset = Changeset.put_embed(changeset, :env_values, env_values)
    {:noreply, assign_changeset(socket, final_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "add:container",
        %{"containers-field" => field_name_str} = _params,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    field_name = String.to_existing_atom(field_name_str)
    containers = Changeset.get_field(changeset, field_name, []) ++ [%Container{}]
    final_changeset = Changeset.put_embed(changeset, field_name, containers)
    {:noreply, assign_changeset(socket, final_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "del:container",
        %{"containers-field" => field_name_str, "idx" => idx} = _params,
        %{assigns: %{changeset: changeset}} = socket
      ) do
    field_name = String.to_existing_atom(field_name_str)

    containers =
      changeset |> Changeset.get_field(field_name, []) |> List.delete_at(String.to_integer(idx))

    final_changeset = Changeset.put_embed(changeset, field_name, containers)
    {:noreply, assign_changeset(socket, final_changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"service" => params}, socket) do
    {changeset, new_service} = Service.validate(params)

    {:noreply,
     socket
     |> assign_changeset(changeset)
     |> assign_url("http://#{knative_host(new_service)}")}
  end

  def handle_event("save", %{"service" => service_params}, socket) do
    save_service(socket, socket.assigns.action, service_params)
  end

  defp save_service(socket, :new, service_params) do
    case Knative.create_service(service_params) do
      {:ok, new_service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Knative service created successfully")
         |> send_info(socket.assigns.save_target, new_service)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp save_service(socket, :edit, service_params) do
    case Knative.update_service(socket.assigns.service, service_params) do
      {:ok, updated_service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Knative service updated successfully")
         |> send_info(socket.assigns.save_target, updated_service)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_changeset(socket, changeset)}
    end
  end

  defp send_info(socket, nil, _service), do: {:noreply, socket}

  defp send_info(socket, target, service) do
    send(target, {socket.assigns.save_info, %{"service" => service}})
    socket
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        id="service-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="col-span-1">
          <.input field={{f, :name}} placeholder="Name" />
          <.input field={{f, :rollout_duration}} placeholder="Rollout Duration" />
        </div>
        <.card class="col-span-1">
          <.data_list>
            <:item title="Namespace">battery-kube</:item>
            <:item title="Url"><%= @url %></:item>
          </.data_list>
        </.card>

        <.h2 class="col-span-2">Containers</.h2>
        <.containers_form form={f} target={@myself} containers_field={:containers} />

        <.h2 class="col-span-2">Environment Variables</.h2>
        <.env_values_form form={f} target={@myself} />
        <.h2 class="col-span-2">Init Containers</.h2>
        <.containers_form form={f} target={@myself} containers_field={:init_containers} />

        <:actions>
          <.button type="submit" phx-disable-with="Saving…" class="sm:col-span-2">
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
