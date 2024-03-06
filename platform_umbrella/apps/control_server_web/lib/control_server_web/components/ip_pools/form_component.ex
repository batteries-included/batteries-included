defmodule ControlServerWeb.Live.IPAddressPoolFormComponent do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.MetalLB.IPAddressPool
  alias ControlServer.MetalLB

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok,
     socket
     |> assign_new(:save_info, fn -> "ip_address_pool:save" end)
     |> assign_new(:save_target, fn -> nil end)}
  end

  @impl Phoenix.LiveComponent
  def update(%{ip_address_pool: ip_address_pool} = assigns, socket) do
    changeset = IPAddressPool.changeset(ip_address_pool)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"ip_address_pool" => params}, socket) do
    {changeset, _data} = IPAddressPool.validate(params)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"ip_address_pool" => pool_params}, socket) do
    save_ip_address_pool(socket, socket.assigns.action, pool_params)
  end

  defp save_ip_address_pool(socket, :new, pool_params) do
    case MetalLB.create_ip_address_pool(pool_params) do
      {:ok, new_pool} ->
        {:noreply,
         socket
         |> put_flash(:info, "IP Address Pool created successfully")
         |> send_info(socket.assigns.save_target, new_pool)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_ip_address_pool(socket, :edit, ip_address_pool_params) do
    case MetalLB.update_ip_address_pool(socket.assigns.ip_address_pool, ip_address_pool_params) do
      {:ok, updated_ip_address_pool} ->
        {:noreply,
         socket
         |> put_flash(:info, "IP Address Pool updated successfully")
         |> send_info(socket.assigns.save_target, updated_ip_address_pool)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp send_info(socket, nil, _ip_address_pool), do: {:noreply, socket}

  defp send_info(socket, target, ip_address_pool) do
    send(target, {socket.assigns.save_info, %{"ip_address_pool" => ip_address_pool}})
    socket
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="ip-pool-form"
        phx-change="validate"
        phx-submit="save"
        phx-target={@myself}
      >
        <.page_header title={@title} back_link={cancel_url()} />

        <.panel>
          <PC.field field={@form[:name]} label="Pool Name" autofocus />
          <PC.field field={@form[:subnet]} label="Subnet CIDR" />

          <.button variant="secondary" link={cancel_url()} class="mr-3">
            Cancel
          </.button>

          <.button variant="primary" type="submit" phx-disable-with="Saving...">
            Save
          </.button>
        </.panel>
      </.form>
    </div>
    """
  end

  defp cancel_url, do: ~p"/ip_address_pools"
end
