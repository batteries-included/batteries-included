defmodule ControlServerWeb.Live.Knative.FormComponent do
  use ControlServerWeb, :live_component

  alias ControlServer.Knative
  alias ControlServer.Knative.Service
  alias CommonUI.Form

  require Logger

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "service:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl true
  def update(%{service: service} = assigns, socket) do
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:url, url(service))
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"service" => params}, socket) do
    {changeset, new_service} = Service.validate(params)

    {:noreply, socket |> assign(:changeset, changeset) |> assign(:url, url(new_service))}
  end

  def handle_event("save", %{"service" => service_params}, socket) do
    save_service(socket, socket.assigns.action, service_params)
  end

  def url(service) do
    "#{service.name}.battery-knative.knative.172.30.0.4.sslip.io"
  end

  defp save_service(socket, :new, service_params) do
    case Knative.create_service(service_params) do
      {:ok, new_service} ->
        {:noreply,
         socket
         |> put_flash(:info, "Knative service created successfully")
         |> send_info(socket.assigns.save_target, new_service)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
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
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp send_info(socket, nil, _service), do: {:noreply, socket}

  defp send_info(socket, target, service) do
    send(target, {socket.assigns.save_info, %{"service" => service}})
    socket
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-10">
      <.form
        let={f}
        for={@changeset}
        id="service-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-2">
          <Form.text_input form={f} field={:name} placeholder="Name" />
          <Form.text_input form={f} field={:image} placeholder="Docker Image" />
          <div class="sm:col-span-2">
            <.labeled_definition title="URL" contents={@url} />
          </div>
        </div>
        <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-2">
          <.button type="submit" phx_disable_with="Saving…" class="sm:col-span-2">
            Save
          </.button>
        </div>
      </.form>
    </div>
    """
  end
end
