defmodule ControlServerWeb.ServicesLive.Postgres.FormComponent do
  use ControlServerWeb, :surface_component

  alias CommonUI.Button
  alias CommonUI.Form.ErrorTag
  alias CommonUI.Form.NumberInput
  alias CommonUI.Form.TextInput

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster

  alias Surface.Components.Form
  alias Surface.Components.Form.Field
  alias Surface.Components.Form.Label

  require Logger

  @doc "The instance of Postgres Cluster being edited/created"
  prop cluster, :map, required: true

  @doc "The action (:new / :edit) for the form"
  prop action, :atom, values: [:new, :edit], required: true

  prop save_info, :string, default: "cluster:save"
  prop save_target, :pid, required: false

  @impl true
  def update(%{cluster: cluster} = assigns, socket) do
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"cluster" => params}, socket) do
    {changeset, data} = Cluster.validate(params)
    {:noreply, assign(socket, changeset: changeset, data: data)}
  end

  def handle_event("save", %{"cluster" => cluster_params}, socket) do
    save_cluster(socket, socket.assigns.action, cluster_params)
  end

  defp save_cluster(socket, :new, cluster_params) do
    case Postgres.create_cluster(cluster_params) do
      {:ok, new_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Postgres Cluster created successfully")
         |> send_info(socket.assigns.save_target, new_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp save_cluster(socket, :edit, cluster_params) do
    case Postgres.update_cluster(socket.assigns.cluster, cluster_params) do
      {:ok, updated_cluster} ->
        {:noreply,
         socket
         |> put_flash(:info, "Postgres Cluster updated successfully")
         |> send_info(socket.assigns.save_target, updated_cluster)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp send_info(socket, nil, _cluster), do: {:noreply, socket}

  defp send_info(socket, target, cluster) do
    send(target, {socket.assigns.save_info, %{"cluster" => cluster}})
    socket
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Form
      for={assigns.changeset}
      change="validate"
      submit="save"
      opts={id: "cluster-form"}
      class="space-y-10"
    >
      <div class="grid grid-cols-1 mt-6 gap-y-6 gap-x-4 sm:grid-cols-6">
        <Field name={:name} class="sm:col-span-6">
          <Label>Name</Label>
          <TextInput />
          <ErrorTag />
        </Field>

        <Field name={:num_instances} class="sm:col-span-3">
          <Label>Number of Pods</Label>
          <NumberInput opts={step: "any"} />
          <ErrorTag />
        </Field>

        <Field name={:postgres_version} class="sm:col-span-3">
          <Label>Postgres Version</Label>
          <TextInput />
          <ErrorTag />
        </Field>

        <Field name={:size} class="sm:col-span-6">
          <Label>Storage Size</Label>
          <TextInput />
          <ErrorTag />
        </Field>

        <div>
          <Button type="submit" theme="primary" opts={phx_disable_with: "Saving…"}>Save</Button>
        </div>
      </div>
    </Form>
    """
  end
end
