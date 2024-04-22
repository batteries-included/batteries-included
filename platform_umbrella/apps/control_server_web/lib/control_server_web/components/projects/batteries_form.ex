defmodule ControlServerWeb.Projects.BatteriesForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias Phoenix.Naming

  def mount(socket) do
    groups = Catalog.groups_for_projects()

    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:tab, :required)
     |> assign(:groups, groups)}
  end

  def update(assigns, socket) do
    required = required_batteries(assigns.data)
    selected = Enum.map(required, &Atom.to_string(&1.type))

    # Turns on batteries that are required for this project
    form =
      required
      |> Map.new(&{Atom.to_string(&1.type), "on"})
      |> to_form()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:required, required)
     |> assign(:selected, selected)
     |> assign(:form, form)}
  end

  def handle_event("tab", %{"id" => id}, socket) do
    # Clear search input if visiting a tab other than "All Batteries"
    params =
      if id != :all do
        Map.put(socket.assigns.form.params, "search", "")
      else
        socket.assigns.form.params
      end

    {:noreply,
     socket
     |> assign(:form, to_form(params))
     |> assign(:tab, String.to_existing_atom(id))}
  end

  @doc """
  This event will persist the selected batteries when moving between tabs.
  """
  def handle_event("toggle", %{"_target" => [target]} = params, socket) do
    selected =
      if params[target] == "on" do
        socket.assigns.selected ++ [target]
      else
        Enum.reject(socket.assigns.selected, &(&1 == target))
      end

    params =
      Map.merge(
        %{"search" => socket.assigns.form.params["search"]},
        Map.new(selected, &{&1, "on"})
      )

    {:noreply,
     socket
     |> assign(:selected, selected)
     |> assign(:form, to_form(params))}
  end

  def handle_event("validate", %{"search" => search} = params, socket) do
    # switch to the "All Batteries" tab when searching
    socket = if search != "", do: assign(socket, :tab, :all), else: socket

    form = socket.assigns.form.params |> Map.merge(params) |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", _params, socket) do
    # Don't actually care about the form data, we just want the selected batteries
    params = Map.new(socket.assigns.selected, &{&1, "on"})

    # Don't create the resources yet, send data to parent liveview
    send(self(), {:next, {__MODULE__, params}})

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="contents">
      <.simple_form
        id={@id}
        for={@form}
        class={@class}
        variant="stepped"
        title="Turn On Batteries You Need"
        description="A place for information about the batteries stage of project creation"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:search]} icon={:magnifying_glass} placeholder="Type to search..." />

        <.tab_bar variant="secondary">
          <:tab
            :if={@required != []}
            phx-click="tab"
            phx-target={@myself}
            phx-value-id={:required}
            selected={@tab == :required}
          >
            Required
          </:tab>

          <:tab
            :for={group <- @groups}
            phx-click="tab"
            phx-value-id={group.id}
            phx-target={@myself}
            selected={@tab == group.id}
          >
            <%= group.name %>
          </:tab>

          <:tab phx-click="tab" phx-target={@myself} phx-value-id={:all} selected={@tab == :all}>
            All Batteries
          </:tab>
        </.tab_bar>

        <.battery_toggle
          :for={battery <- search_filter(@required, @form[:search].value)}
          :if={@tab == :required}
          installed={has_battery?(@installed, battery)}
          required={has_battery?(@required, battery)}
          battery={battery}
          form={@form}
        />

        <%= for group <- @groups do %>
          <.battery_toggle
            :for={battery <- search_filter(Catalog.all(group.id), @form[:search].value)}
            :if={@tab == group.id}
            installed={has_battery?(@installed, battery)}
            required={has_battery?(@required, battery)}
            battery={battery}
            form={@form}
          />
        <% end %>

        <.battery_toggle
          :for={battery <- search_filter(Catalog.all(), @form[:search].value)}
          :if={@tab == :all}
          installed={has_battery?(@installed, battery)}
          required={has_battery?(@required, battery)}
          battery={battery}
          form={@form}
        />

        <:actions>
          <%= render_slot(@inner_block) %>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  attr :installed, :boolean, default: false
  attr :required, :boolean, default: false
  attr :battery, CatalogBattery, required: true
  attr :form, Phoenix.HTML.Form, required: true

  defp battery_toggle(assigns) do
    ~H"""
    <div class="flex items-start justify-between gap-x-12 pb-8 last:pb-0 border-b border-b-gray-lighter last:border-b-0">
      <div>
        <div class="flex items-center gap-3 mb-2">
          <h3 class="text-xl font-semibold">
            <%= Naming.humanize(@battery.type) %>
          </h3>

          <div
            :if={@installed}
            class="bg-gray-lighter dark:bg-gray-darkest-tint text-xs text-white dark:text-gray-darker-tint font-semibold rounded px-1 py-0.5 whitespace-nowrap"
          >
            ALREADY INSTALLED
          </div>
        </div>

        <p class="text-sm">
          <%= @battery.description %>
        </p>
      </div>

      <.input
        :if={!@installed}
        type="switch"
        field={@form[@battery.type]}
        disabled={@required}
        phx-change="toggle"
      />
    </div>
    """
  end

  defp has_battery?(batteries, %{type: type} = battery) when is_binary(type) do
    has_battery?(batteries, Map.put(battery, :type, String.to_existing_atom(type)))
  end

  defp has_battery?(batteries, battery) do
    Enum.any?(batteries, &(&1.type == battery.type))
  end

  defp search_filter(batteries, nil), do: batteries

  defp search_filter(batteries, search) do
    pattern = search |> Regex.escape() |> Regex.compile!([:caseless])

    # run a simple search against the battery's type and description
    Enum.filter(batteries, fn battery ->
      Regex.match?(pattern, Atom.to_string(battery.type) <> battery.description)
    end)
  end

  # Gets a list of all the required batteries for form data returned from a subform.
  # This is recursive, so it will also get all the dependencies for each battery.
  defp required_batteries(data) do
    data
    |> Enum.map(fn {_, v} ->
      Enum.map(
        Map.keys(v),
        &case &1 do
          "postgres" -> [:cloudnative_pg]
          "postgres_ids" -> [:cloudnative_pg]
          "redis" -> [:redis]
          "jupyter" -> [:notebooks]
          _ -> nil
        end
      )
    end)
    |> List.flatten()
    |> Enum.filter(&(&1 != nil))
    |> Enum.map(&Catalog.get_recursive/1)
    |> List.flatten()
    |> Enum.uniq()
  end
end
