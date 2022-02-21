defmodule ControlServerWeb.ServicesLive.JupyterLabNotebook.Display do
  use Phoenix.Component
  use PetalComponents

  alias ControlServerWeb.Router.Helpers, as: Routes

  defp assign_defaults(assigns) do
    assigns
    |> assign_new(:delete_event, fn -> "delete_notebook" end)
    |> assign_new(:start_event, fn -> "start_notebook" end)
    |> assign_new(:notebooks, fn -> [] end)
  end

  def notebook_display(assigns) do
    assigns = assign_defaults(assigns)

    ~H"""
    <.h3>
      Jupyter Notebooks
    </.h3>
    <table class="min-w-full divide-y divide-gray-200">
      <thead>
        <tr>
          <th
            scope="col"
            class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
          >
            Name
          </th>
          <th
            scope="col"
            class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
          >
            Version
          </th>
          <th
            scope="col"
            class="px-6 py-3 text-xs font-medium tracking-wider text-left text-gray-500 uppercase"
          >
            Actions
          </th>
        </tr>
      </thead>
      <tbody>
        <%= for notebook <- @notebooks do %>
          <.notebook_row notebook={notebook} delete_event={@delete_event} />
        <% end %>
      </tbody>
    </table>

    <.button type="primary" phx-click={@start_event}>
      Start New Notebook
    </.button>
    """
  end

  defp notebook_path(notebook), do: "http://anton2:8081/x/notebooks/#{notebook.name}"

  defp notebook_row(assigns) do
    ~H"""
    <tr id="row-notebook-{@notebook.id}">
      <td>
        <%= @notebook.name %>
      </td>
      <td>
        <%= @notebook.image %>
      </td>
      <td>
        <span>
          <.button to={notebook_path(@notebook)} variant="shadow" link_type="a">
            Open Notebook
            <Heroicons.Solid.external_link class={"w-5 h-5"} />
          </.button>
        </span>
        |
        <span>
          <.link
            label="Delete"
            to="#"
            phx-click={@delete_event}
            phx-value-id={@notebook.id}
            data={[confirm: "Are you sure?"]}
          />
        </span>
      </td>
    </tr>
    """
  end

  def notebook_show_path(notebook),
    do:
      Routes.services_jupyter_lab_notebook_show_path(
        ControlServerWeb.Endpoint,
        :index,
        notebook.id
      )
end
