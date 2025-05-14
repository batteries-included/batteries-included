defmodule ControlServerWeb.Projects.ImportSelectSnapshotForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.ProjectsSubcomponents

  alias KubeServices.ET.HomeBaseClient

  @description """
  Select a snapshot to import into your project. You can search for a specific snapshot by name.
  """

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    selected = get_in(assigns.data, [__MODULE__, "selected_snapshot_id"])
    input = %{"selected_snapshot_id" => selected}

    input =
      if selected do
        Map.put(input, selected, true)
      else
        input
      end

    form = to_form(input)

    {:ok,
     socket
     |> assign(:form, form)
     |> assign(:selected_snapshot_id, selected)
     |> assign_snapshots()
     |> assign_selected_snapshot()
     |> assign(assigns)}
  end

  def handle_event("submit", params, socket) do
    form = to_form(params)
    selected_snapshot_id = Map.get(form.params, "selected_snapshot_id", "") || nil

    send(self(), {:next, {__MODULE__, %{"selected_snapshot_id" => selected_snapshot_id}}})

    {:noreply, socket |> assign(:form, form) |> assign_snapshots()}
  end

  def handle_event("validate", params, %{assigns: %{form: old_form}} = socket) do
    # If there's a new selected id in the snapshot_select_params that wasn't true in the old_snapshot_select_form,
    # we need to set it to true in the new form and all others to false
    # otherwise we simply keep the params as they are
    newly_selected_ids = get_newly_selected_ids(params, old_form)
    search = Map.get(params, "search", "") || Map.get(old_form.params, "search", "") || ""

    form =
      case newly_selected_ids do
        [] = _empty ->
          # When there's a click we to un-select we still want the search to remain
          new_params = Map.put(params, "search", search)
          to_form(new_params)

        newly_selected_ids ->
          params
          |> Map.new(fn {id, _} ->
            cond do
              id in newly_selected_ids ->
                {id, true}

              id == "search" ->
                {id, search}

              true ->
                {id, false}
            end
          end)
          |> to_form()
      end

    {:noreply,
     socket
     |> assign(:form, form)
     |> assign_snapshots()
     |> assign_selected_snapshot()}
  end

  defp get_newly_selected_ids(params, old_form) do
    params
    |> Enum.filter(fn {id, value} ->
      # search isn't used to flop selected ids
      # so we need to filter it out
      # params are strings
      # while the form params are parsed into booleans
      # so to notice a new selection we need the paramss
      # to be "true" while the old form params are not true
      id != "search" && value == "true" && Map.get(old_form.params, id) != true
    end)
    |> Enum.map(fn {id, _value} -> id end)
  end

  defp assign_snapshots(%{assigns: %{form: form}} = socket) do
    search = Map.get(form.params, "search", "") || ""

    snapshots = get_snapshot_list(search)

    form =
      snapshots
      |> Map.new(fn snapshot ->
        {snapshot.id, Map.get(form.params, snapshot.id, false)}
      end)
      |> Map.put("search", search)
      |> to_form()

    socket
    |> assign(:snapshots, snapshots)
    |> assign(:form, form)
  end

  defp get_snapshot_list(search) do
    snapshots =
      case HomeBaseClient.list_snapshots() do
        {:ok, snapshots} -> snapshots
        {:error, _} -> []
      end

    Enum.filter(snapshots, fn snapshot ->
      search == nil || String.contains?(snapshot.name, search)
    end)
  end

  defp assign_selected_snapshot(%{assigns: %{form: form}} = socket) do
    selected_snapshot_id =
      form.params
      |> Enum.filter(fn {id, value} -> id != "search" && value == true end)
      |> Enum.map(fn {id, _} -> id end)
      |> List.first()

    assign(socket, :selected_snapshot_id, selected_snapshot_id)
  end

  defp description(_, nil), do: @description

  defp description(snapshots, selected_snapshot_id) do
    case Enum.find(snapshots, fn snapshot -> snapshot.id == selected_snapshot_id end) do
      nil -> @description
      snapshot -> @description <> snapshot.description
    end
  end

  def render(assigns) do
    ~H"""
    <div class="contents" id={"contents_import_#{@id}"}>
      <.form
        id={"form_#{@id}"}
        for={@form}
        class={@class}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="submit"
      >
        <.subform
          flash={@flash}
          title="Snapshot Details"
          description={description(@snapshots, @selected_snapshot_id)}
        >
          <.flex column class={@class}>
            <.input
              field={@form[:search]}
              icon={:magnifying_glass}
              placeholder="Type to search..."
              debounce="10"
            />

            <.flex column class="max-h-128 overflow-y-auto">
              <.h3>Choose Snapshot For Import</.h3>
              <%= for snapshot <- @snapshots do %>
                <.input field={@form[snapshot.id]} type="switch" label={snapshot.name} />
              <% end %>
            </.flex>
          </.flex>

          <.input name={:selected_snapshot_id} type="hidden" value={@selected_snapshot_id} />
        </.subform>
      </.form>
    </div>
    """
  end
end
