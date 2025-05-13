defmodule ControlServerWeb.Projects.ImportForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias KubeServices.ET.HomeBaseClient

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    search_form = assigns |> Map.get(:data, %{}) |> to_form()

    {:ok,
     socket
     |> assign(:search_form, search_form)
     |> assign_snapshots()
     |> assign(assigns)}
  end

  def handle_event("search_validate", search_params, socket) do
    search_form = to_form(search_params)
    {:noreply, socket |> assign(:search_form, search_form) |> assign_snapshots()}
  end

  def handle_event("search_submit", search_params, socket) do
    search_form = to_form(search_params)
    {:noreply, socket |> assign(:search_form, search_form) |> assign_snapshots()}
  end

  defp assign_snapshots(%{assigns: %{search_form: search_form}} = socket) do
    search = Map.get(search_form.params, "search", "")

    snapshots = get_snapshots(search)

    assign(socket, :snapshots, snapshots)
  end

  defp get_snapshots(search) do
    snapshots =
      case HomeBaseClient.list_snapshots() do
        {:ok, snapshots} -> snapshots
        {:error, _} -> []
      end

    snapshots =
      Enum.filter(snapshots, fn snapshot ->
        String.contains?(snapshot.name, search)
      end)

    snapshots
  end

  def render(assigns) do
    ~H"""
    <div class={["contents", @class]} id={"contents_import_#{@id}"}>
      <.form
        id={"search_form_#{@id}"}
        for={@search_form}
        phx-target={@myself}
        phx-change="search_validate"
        phx-submit="search_submit"
      >
        <.input
          field={@search_form[:search]}
          icon={:magnifying_glass}
          placeholder="Type to search..."
          debounce="10"
        />
      </.form>

      <.flex column>
        <%= for snapshot <- @snapshots do %>
          <.button phx-click="import_snapshot" phx-value-snapshot={snapshot.id} phx-target={@myself}>
            {snapshot.name}
          </.button>
        <% end %>
      </.flex>
    </div>
    """
  end
end
