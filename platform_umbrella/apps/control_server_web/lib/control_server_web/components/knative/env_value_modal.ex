defmodule ControlServerWeb.Knative.EnvValueModal do
  @moduledoc false

  use ControlServerWeb, :live_component

  import CommonCore.Resources.FieldAccessors
  import CommonUI.TabBar

  alias CommonCore.Knative.EnvValue
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{env_value: env_value} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_configs()
     |> assign_secrets()
     |> assign_changeset(EnvValue.changeset(env_value, %{}))}
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  defp assign_configs(socket) do
    namespace = "battery-knative"
    assign(socket, configs: :config_map |> KubeServices.KubeState.get_all() |> Enum.filter(&(namespace(&1) == namespace)))
  end

  defp assign_secrets(socket) do
    namespace = "battery-knative"
    assign(socket, secrets: :secret |> KubeServices.KubeState.get_all() |> Enum.filter(&(namespace(&1) == namespace)))
  end

  @impl Phoenix.LiveComponent
  def handle_event("close_modal", _, socket) do
    ControlServerWeb.Live.Knative.FormComponent.update_env_value(nil)
    {:noreply, socket}
  end

  def handle_event("cancel", _, socket) do
    ControlServerWeb.Live.Knative.FormComponent.update_env_value(nil)
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate_env_value", %{"env_value" => params}, socket) do
    changeset = EnvValue.changeset(socket.assigns.env_value, params)
    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event(source_type, _, socket) when source_type in ["value", "config", "secret"] do
    changeset = Changeset.put_change(socket.assigns.changeset, :source_type, source_type)
    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event("save_env_value", %{"env_value" => params}, socket) do
    changeset = EnvValue.changeset(socket.assigns.env_value, params)

    if changeset.valid? do
      ControlServerWeb.Live.Knative.FormComponent.update_env_value(Changeset.apply_changes(changeset))
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  defp extract_source_type(changeset) do
    Changeset.get_field(changeset, :source_type)
  end

  defp is_value(changeset) do
    extract_source_type(changeset) in [:value, "value"]
  end

  defp is_config(changeset) do
    extract_source_type(changeset) in [:config, "config"]
  end

  defp is_secret(changeset) do
    extract_source_type(changeset) in [:secret, "secret"]
  end

  defp value_inputs(assigns) do
    ~H"""
    <.flex class="col-span-2">
      <PC.field field={@form[:value]} wrapper_class="w-full" placeholder="your.service.creds" />
    </.flex>
    """
  end

  defp resource_inputs(assigns) do
    ~H"""
    <.flex class="col-span-2 flex-col">
      <PC.field
        label={@label}
        field={@form[:source_name]}
        wrapper_class="w-full"
        type="select"
        options={Enum.map(@resources, &name/1)}
      />
      <PC.field field={@form[:source_key]} wrapper_class="w-full" />
    </.flex>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <PC.modal id={"#{@id}-modal"} title="Environment Variable" close_modal_target={@myself}>
        <.form
          for={@form}
          id="env_value-form"
          phx-change="validate_env_value"
          phx-submit="save_env_value"
          phx-target={@myself}
        >
          <.flex class="flex-col" gaps="2">
            <PC.field
              field={@form[:name]}
              autofocus
              placeholder="ENV_VARIABLE_NAME"
              wrapper_class="col-span-2"
            />
            <.tab_bar class="col-span-2">
              <.tab_item phx-click="value" phx-target={@myself} selected={is_value(@changeset)}>
                Explicit Value
              </.tab_item>
              <.tab_item phx-click="config" phx-target={@myself} selected={is_config(@changeset)}>
                Config Map
              </.tab_item>
              <.tab_item phx-click="secret" phx-target={@myself} selected={is_secret(@changeset)}>
                Secret
              </.tab_item>
            </.tab_bar>
            <PC.input type="hidden" field={@form[:source_type]} />
            <.value_inputs :if={is_value(@changeset)} form={@form} />
            <.resource_inputs
              :if={is_config(@changeset)}
              form={@form}
              resources={@configs}
              label="Config Map"
            />
            <.resource_inputs
              :if={is_secret(@changeset)}
              form={@form}
              resources={@secrets}
              label="Secret"
            />
            <.flex class="justify-end col-span-2">
              <.button phx-target={@myself} phx-click="cancel" type="button">
                Cancel
              </.button>
              <PC.button type="submit" phx-disable-with="Saving...">Save</PC.button>
            </.flex>
          </.flex>
        </.form>
      </PC.modal>
    </div>
    """
  end
end
