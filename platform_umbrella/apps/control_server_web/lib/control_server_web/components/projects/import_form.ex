defmodule ControlServerWeb.Projects.ImportForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias KubeServices.ET.HomeBaseClient

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    search_form = to_form(%{})
    snapshot_select_form = to_form(%{})

    {:ok,
     socket
     |> assign(:search_form, search_form)
     |> assign(:snapshot_select_form, snapshot_select_form)
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

  def handle_event("snapshot_select_validate", snapshot_select_params, socket) do
    snapshot_select_form = to_form(snapshot_select_params)
    {:noreply, socket |> assign(:snapshot_select_form, snapshot_select_form) |> assign_snapshots()}
  end

  defp assign_snapshots(%{assigns: %{search_form: search_form, snapshot_select_form: snapshot_select_form}} = socket) do
    search = Map.get(search_form.params, "search", "")

    snapshots = get_snapshots(search)

    snapshot_select_form =
      snapshots
      |> Map.new(fn snapshot ->
        {snapshot.id, Map.get(snapshot_select_form.params, snapshot.id, false)}
      end)
      |> to_form()

    socket
    |> assign(:snapshots, snapshots)
    |> assign(:snapshot_select_form, snapshot_select_form)
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
    <div class={["flex", "flex-col", "gap-4", "lg:gap-6", @class]} id={"contents_import_#{@id}"}>
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

      <.flex column class="min-h-96 max-h-128">
        <.form
          id={"snapshot_select_form_#{@id}"}
          for={@snapshot_select_form}
          phx-target={@myself}
          phx-change="snapshot_select_validate"
          phx-submit="snapshot_select_submit"
        >
          <%= for snapshot <- @snapshots do %>
            <.input field={@snapshot_select_form[snapshot.id]} type="switch" label={snapshot.name} />
          <% end %>
        </.form>
      </.flex>
    </div>
    """
  end
end
