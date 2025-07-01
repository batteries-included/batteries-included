defmodule ControlServerWeb.Containers.VolumeModal do
  @moduledoc false
  use ControlServerWeb, :live_component

  import CommonCore.Resources.FieldAccessors

  alias CommonCore.TraditionalServices.Volume
  alias Ecto.Changeset

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(%{volume: volume, idx: idx, update_func: update_func, namespace: namespace, id: id} = _assigns, socket) do
    {:ok,
     socket
     |> assign(namespace: namespace)
     |> assign_id(id)
     |> assign_idx(idx)
     |> assign_volume(volume)
     |> assign_changeset(Volume.changeset(volume, %{}))
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

  defp assign_volume(socket, volume) do
    assign(socket, volume: volume)
  end

  defp assign_changeset(socket, changeset) do
    assign(socket, changeset: changeset, form: to_form(changeset))
  end

  # defp assign_form(socket, changeset) do
  #   assign(socket, form: changeset |> Changeset.apply_action() |> Map.from_struct() |> to_form(as: "volume"))
  # end

  # defp assign_config(%{assigns: assigns} = socket) do
  #   config_module = if assigns[:volume], do: Volume.for_type(assigns.volume.type), else: :empty_dir
  #   config = if assigns[:volume], do: assigns.volume.config, else: struct(config_module)
  #   changeset = config_module.changeset(config, %{})
  #
  #   assign(socket, config_module: config_module, config: config, changeset: changeset, form: to_form(changeset))
  # end

  defp assign_configs(%{assigns: %{namespace: namespace}} = socket) do
    assign(socket,
      configs:
        :config_map
        |> KubeServices.KubeState.get_all()
        |> Enum.filter(&(namespace(&1) == namespace))
    )
  end

  defp assign_secrets(%{assigns: %{namespace: namespace}} = socket) do
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
  def handle_event("validate_volume", %{"volume" => params}, socket) do
    changeset =
      socket.assigns.volume
      |> Volume.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event(type, _, socket) when type in ~w(config_map empty_dir secret) do
    changeset = Changeset.put_change(socket.assigns.changeset, :type, type)
    {:noreply, assign_changeset(socket, changeset)}
  end

  def handle_event(
        "save_volume",
        %{"volume" => params},
        %{assigns: %{volume: volume, idx: idx, update_func: update_func}} = socket
      ) do
    changeset =
      volume
      |> Volume.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      new_volume = Changeset.apply_changes(changeset)

      update_func.(new_volume, idx)
    end

    {:noreply, assign_changeset(socket, changeset)}
  end

  defp get_type(changeset) do
    Changeset.get_field(changeset, :type)
  end

  defp empty_dir_selected?(changeset) do
    get_type(changeset) in [:empty_dir, "empty_dir"]
  end

  defp config_map_selected?(changeset) do
    get_type(changeset) in [:config_map, "config_map"]
  end

  defp secret_selected?(changeset) do
    get_type(changeset) in [:secret, "secret"]
  end

  # defp extract_keys(resources, name) do
  #   resources
  #   |> Enum.find(%{}, fn r -> name(r) == name end)
  #   |> Map.get("data", %{})
  #   |> Map.keys()
  # end

  # defp value_inputs(assigns) do
  #   ~H"""
  #   <.field>
  #     <:label>Value</:label>
  #     <.input field={@form[:value]} placeholder="your.service.creds" />
  #   </.field>
  #   """
  # end
  #

  # field :default_mode, :integer
  # field :name, :string
  # field :optional, :boolean, default: false

  defp resource_inputs(assigns) do
    ~H"""
    <.fieldset>
      <.field>
        <:label>{@label}</:label>
        <.input
          type="select"
          field={@form[:name]}
          placeholder="Select Source"
          options={Enum.map(@resources, &name/1)}
        />
      </.field>
    </.fieldset>
    """
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="contents">
      <.form
        for={@form}
        id="volume-form"
        phx-change="validate_volume"
        phx-submit="save_volume"
        phx-target={@myself}
      >
        <.modal show size="lg" id={"#{@id}-modal"} on_cancel={JS.push("cancel", target: @myself)}>
          <:title>Volume</:title>

          <.fieldset>
            <.field>
              <:label>Name</:label>
              <.input field={@form[:name]} placeholder="volume-name" autofocus />
            </.field>

            <.tab_bar variant="secondary">
              <:tab
                phx-click="empty_dir"
                phx-target={@myself}
                selected={empty_dir_selected?(@changeset)}
              >
                Empty Dir
              </:tab>
              <:tab
                phx-click="config_map"
                phx-target={@myself}
                selected={config_map_selected?(@changeset)}
              >
                Config Map
              </:tab>
              <:tab phx-click="secret" phx-target={@myself} selected={secret_selected?(@changeset)}>
                Secret
              </:tab>
            </.tab_bar>
          </.fieldset>

          <:actions cancel="Cancel">
            <.button variant="primary" type="submit" phx-disable-with="Saving...">Save</.button>
          </:actions>
        </.modal>
      </.form>
    </div>
    """
  end

  # <.value_inputs :if={value_selected?(@changeset)} form={@form} />
  #
  # <.resource_inputs
  #   :if={config_map_selected?(@changeset)}
  #   form={@form[:config]}
  #   resources={@configs}
  #   label="Config Map"
  # />
  #
  # <.resource_inputs
  #   :if={secret_selected?(@changeset)}
  #   form={@form[:config]}
  #   resources={@secrets}
  #   label="Secret"
  # />
  #
end
