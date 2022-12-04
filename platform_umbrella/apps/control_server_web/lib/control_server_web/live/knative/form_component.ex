defmodule ControlServerWeb.Live.Knative.FormComponent do
  use ControlServerWeb, :live_component

  alias ControlServer.Knative
  alias ControlServer.Knative.Service
  alias KubeResources.KnativeServing

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "service:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(%{service: service} = assigns, socket) do
    changeset = Knative.change_service(service)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:url, KnativeServing.url(service))
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"service" => params}, socket) do
    {changeset, new_service} = Service.validate(params)

    {:noreply,
     socket
     |> assign(:changeset, changeset)
     |> assign(:url, KnativeServing.url(new_service))}
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
        <.input field={{f, :name}} placeholder="Name" />
        <.input field={{f, :image}} placeholder="Docker Image" />
        <div class="sm:col-span-2">
          <.labeled_definition title="URL" contents={@url} />
        </div>

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
