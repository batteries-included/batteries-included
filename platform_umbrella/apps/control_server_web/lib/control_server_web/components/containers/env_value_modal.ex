defmodule ControlServerWeb.Containers.EnvValueModal do
  @moduledoc false
  use ControlServerWeb, :live_component

  import CommonCore.Resources.FieldAccessors

  alias CommonCore.Containers.EnvValue
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{env_value: env_value, idx: idx, update_func: update_func, id: id} = _assigns, socket) do
    {:ok,
     socket
     |> assign_id(id)
     |> assign_idx(idx)
     |> assign_env_value(env_value)
     |> assign_changeset(EnvValue.changeset(env_value, %{}))
     |> assign_update_func(update_func)
     |> assign_configs()
     |> assign_secrets()}
  end

  defp assign_id(socket, id) do
    assign(socket, id: id)
  end

  defp assign_idx(socket, idx) do
    assign(socket, idx: idx)
  end

  defp assign_update_func(socket, update_func) do
    assign(socket, update_func: update_func)
  end

  defp assign_env_value(socket, env_value) do
    assign(socket, env_value: env_value)
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  defp assign_configs(socket) do
    namespace = "battery-knative"

    assign(socket,
      configs:
        :config_map
        |> KubeServices.KubeState.get_all()
        |> Enum.filter(&(namespace(&1) == namespace))
    )
  end

  defp assign_secrets(socket) do
    namespace = "battery-knative"

    assign(socket,
      secrets: :secret |> KubeServices.KubeState.get_all() |> Enum.filter(&(namespace(&1) == namespace))
    )
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel", _, %{assigns: %{update_func: update_func}} = socket) do
    update_func.(nil, nil)
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

  def handle_event(
        "save_env_value",
        %{"env_value" => params},
        %{assigns: %{env_value: env_value, idx: idx, update_func: update_func}} = socket
      ) do
    changeset = EnvValue.changeset(env_value, params)

    if changeset.valid? do
      new_env_value = Changeset.apply_changes(changeset)

      update_func.(new_env_value, idx)
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  defp extract_source_type(changeset) do
    Changeset.get_field(changeset, :source_type)
  end

  defp value_selected?(changeset) do
    extract_source_type(changeset) in [:value, "value"]
  end

  defp config_selected?(changeset) do
    extract_source_type(changeset) in [:config, "config"]
  end

  defp secret_selected?(changeset) do
    extract_source_type(changeset) in [:secret, "secret"]
  end

  defp extract_keys(resources, name) do
    resources
    |> Enum.find(%{}, fn r -> name(r) == name end)
    |> Map.get("data", %{})
    |> Map.keys()
  end

  defp value_inputs(assigns) do
    ~H"""
    <.input label="Value" field={@form[:value]} placeholder="your.service.creds" />
    """
  end

  defp resource_inputs(assigns) do
    ~H"""
    <.flex column>
      <.input
        label={@label}
        field={@form[:source_name]}
        type="select"
        placeholder="Select Source"
        options={Enum.map(@resources, &name/1)}
      />
      <.input
        label="Key"
        field={@form[:source_key]}
        type="select"
        placeholder="Select Key"
        options={extract_keys(@resources, @form[:source_name].value || "")}
      />
    </.flex>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id="env_value-form"
        phx-change="validate_env_value"
        phx-submit="save_env_value"
        phx-target={@myself}
      >
        <.modal show size="lg" id={"#{@id}-modal"} on_cancel={JS.push("cancel", target: @myself)}>
          <:title>Environment Variable</:title>

          <.flex column>
            <.input label="Name" field={@form[:name]} autofocus placeholder="ENV_VARIABLE_NAME" />
            <.tab_bar variant="secondary">
              <:tab phx-click="value" phx-target={@myself} selected={value_selected?(@changeset)}>
                Explicit Value
              </:tab>
              <:tab phx-click="config" phx-target={@myself} selected={config_selected?(@changeset)}>
                Config Map
              </:tab>
              <:tab phx-click="secret" phx-target={@myself} selected={secret_selected?(@changeset)}>
                Secret
              </:tab>
            </.tab_bar>
            <.input type="hidden" field={@form[:source_type]} />
            <.value_inputs :if={value_selected?(@changeset)} form={@form} />
            <.resource_inputs
              :if={config_selected?(@changeset)}
              form={@form}
              resources={@configs}
              label="Config Map"
            />
            <.resource_inputs
              :if={secret_selected?(@changeset)}
              form={@form}
              resources={@secrets}
              label="Secret"
            />
          </.flex>

          <:actions cancel="Cancel">
            <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
          </:actions>
        </.modal>
      </.form>
    </div>
    """
  end
end
