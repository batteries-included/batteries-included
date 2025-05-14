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

  def handle_event(
        "snapshot_select_validate",
        snapshot_select_params,
        %{assigns: %{snapshot_select_form: old_snapshot_select_form}} = socket
      ) do
    # If there's a new selected id in the snapshot_select_params that wasn't true in the old_snapshot_select_form,
    # we need to set it to true in the new snapshot_select_form and all others to false
    # otherwise we simply keep the params as they are

    newly_selected_ids =
      snapshot_select_params
      |> Map.keys()
      |> Enum.filter(fn {id, value} ->
        # params are strings
        # while the form params are parsed into booleans
        # so to notice a new selection we need the params
        # to be "true" while the old form params are not true
        value == "true" && Map.get(old_snapshot_select_form.params, id) != true
      end)
      |> Enum.map(fn {id, _value} -> id end)

    snapshot_select_form =
      case newly_selected_ids do
        [] = _empty ->
          to_form(snapshot_select_params)

        newly_selected_ids ->
          snapshot_select_params
          |> Map.new(fn {id, _} ->
            if id in newly_selected_ids do
              {id, true}
            else
              {id, false}
            end
          end)
          |> to_form()
      end

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

    Enum.filter(snapshots, fn snapshot ->
      String.contains?(snapshot.name, search)
    end)
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

      <.flex column class="min-h-96 max-h-128 overflow-y-auto">
        <.h3>Choose Snapshot For Import</.h3>
        <.form
          id={"snapshot_select_form_#{@id}"}
          for={@snapshot_select_form}
          phx-target={@myself}
          phx-change="snapshot_select_validate"
          phx-submit="snapshot_select_submit"
          class="contents"
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
