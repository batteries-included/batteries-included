defmodule ServerWeb.RawConfigLive.FormComponent do
  @moduledoc """
  Edit these things? Will the editing of these really ever make sense?
  """
  use ServerWeb, :live_component

  alias Server.Configs

  @impl true
  def update(%{raw_config: raw_config} = assigns, socket) do
    changeset = Configs.change_raw_config(raw_config)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"raw_config" => raw_config_params}, socket) do
    changeset =
      socket.assigns.raw_config
      |> Configs.change_raw_config(raw_config_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"raw_config" => raw_config_params}, socket) do
    save_raw_config(socket, socket.assigns.action, raw_config_params)
  end

  defp save_raw_config(socket, :edit, raw_config_params) do
    case Configs.update_raw_config(socket.assigns.raw_config, raw_config_params) do
      {:ok, _raw_config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Raw config updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_raw_config(socket, :new, raw_config_params) do
    case Configs.create_raw_config(raw_config_params) do
      {:ok, _raw_config} ->
        {:noreply,
         socket
         |> put_flash(:info, "Raw config created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
