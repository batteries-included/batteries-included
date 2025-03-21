defmodule ControlServerWeb.Projects.AIForm do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.ProjectsSubcomponents

  alias CommonCore.Ecto.Validations
  alias CommonCore.Notebooks.JupyterLabNotebook
  alias CommonCore.Ollama.ModelInstance
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Util.Memory
  alias ControlServer.Ollama
  alias ControlServer.Postgres
  alias ControlServerWeb.OllamaFormSubcomponents
  alias ControlServerWeb.PostgresFormSubcomponents
  alias ControlServerWeb.Projects.ProjectForm

  @description """
  Jupyter is a web application that lets you create and share documents
  that include live code, equations, AI models, and other resources.

  Choose the instance size for your project's Jupyter notebook, and add
  an optional Postgres database. The database URL will automatically be
  added to the instance's environment variables.
  """

  def update(assigns, socket) do
    {class, assigns} = Map.pop(assigns, :class)

    form_data = get_in(assigns, [:data, __MODULE__]) || %{}
    resource_name = ProjectForm.get_name_for_resource(assigns)

    jupyter_changeset =
      JupyterLabNotebook.changeset(
        KubeServices.SmartBuilder.new_jupyter(),
        Map.get(form_data, "jupyter", %{name: resource_name})
      )

    ollama_changeset =
      ModelInstance.changeset(
        KubeServices.SmartBuilder.new_model_instance_params(),
        Map.get(form_data, "ollama", %{name: resource_name})
      )

    postgres_changeset =
      PGCluster.changeset(
        KubeServices.SmartBuilder.new_postgres(),
        Map.get(form_data, "postgres", %{name: resource_name}),
        range_ticks: PGCluster.compact_storage_range_ticks()
      )

    form =
      to_form(%{
        "jupyter" => to_form(jupyter_changeset, as: :jupyter),
        "need_postgres" => Map.get(form_data, "need_postgres", false),
        "postgres" => postgres_changeset,
        "need_ollama" => Map.get(form_data, "need_ollama", false),
        "ollama" => to_form(ollama_changeset, as: :ollama)
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, form)
     |> assign(:class, class)
     |> assign(:db_type, Map.get(form_data, "db_type", :new))
     |> assign(:ollama_type, Map.get(form_data, "ollama_type", :new))}
  end

  def handle_event("db_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :db_type, String.to_existing_atom(type))}
  end

  def handle_event("ollama_type", %{"type" => type}, socket) do
    {:noreply, assign(socket, :ollama_type, String.to_existing_atom(type))}
  end

  def handle_event("validate", params, socket) do
    jupyter_changeset =
      %JupyterLabNotebook{}
      |> JupyterLabNotebook.changeset(params["jupyter"])
      |> Map.put(:action, :validate)

    postgres_changeset =
      %PGCluster{}
      |> PGCluster.changeset(params["postgres"], range_ticks: PGCluster.compact_storage_range_ticks())
      |> Map.put(:action, :validate)

    ollama_changeset =
      %ModelInstance{}
      |> ModelInstance.changeset(params["ollama"])
      |> Map.put(:action, :validate)

    form =
      params
      |> Map.put("jupyter", to_form(jupyter_changeset, as: :jupyter))
      |> Map.put("postgres", postgres_changeset)
      |> Map.put("ollama", to_form(ollama_changeset, as: :ollama))
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("change_storage_size_range", %{"value" => value}, socket) do
    handle_event(
      "change_storage_size_range",
      %{"postgres" => %{"virtual_storage_size_range_value" => value}},
      socket
    )
  end

  def handle_event(
        "change_storage_size_range",
        %{"postgres" => %{"virtual_storage_size_range_value" => range_value}},
        socket
      ) do
    postgres_changeset =
      socket.assigns.form.params["postgres"]
      |> PGCluster.put_storage_size(range_value, PGCluster.compact_storage_range_ticks())
      |> Map.put(:action, :validate)

    form =
      socket.assigns.form.params
      |> Map.put("postgres", postgres_changeset)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", params, socket) do
    params =
      params
      |> clean_params()
      |> Map.put("db_type", socket.assigns.db_type)
      |> Map.put("ollama_type", socket.assigns.ollama_type)

    if Validations.subforms_valid?(params, %{
         "jupyter" => &JupyterLabNotebook.changeset(%JupyterLabNotebook{}, &1),
         "postgres" => &PGCluster.changeset(%PGCluster{}, &1, range_ticks: PGCluster.compact_storage_range_ticks()),
         "ollama" => &ModelInstance.changeset(%ModelInstance{}, &1)
       }) do
      # Don't create the resources yet, send data to parent liveview
      send(self(), {:next, {__MODULE__, params}})
    end

    {:noreply, socket}
  end

  defp clean_params(params) do
    Map.take(params, [
      "need_postgres",
      "need_ollama",
      "jupyter",
      if(normalize_value("checkbox", params["need_postgres"]) && params["db_type"] == "new", do: "postgres"),
      if(normalize_value("checkbox", params["need_postgres"]) && params["db_type"] == "existing", do: "postgres_ids"),
      if(normalize_value("checkbox", params["need_ollama"]) && params["ollama_type"] == "new", do: "ollama"),
      if(normalize_value("checkbox", params["need_ollama"]) && params["ollama_type"] == "existing", do: "ollama_ids")
    ])
  end

  def render(assigns) do
    assigns = assign(assigns, :description, @description)

    ~H"""
    <div class="contents">
      <.form
        id={@id}
        for={@form}
        class={@class}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.subform flash={@flash} title="Artificial Intelligence" description={@description}>
          <.fieldset responsive>
            <.field>
              <:label>Name of the Jupyter notebook</:label>
              <.input field={@form[:jupyter].value[:name]} />
            </.field>

            <.field>
              <:label>Size of the Jupyter notebook</:label>
              <.input
                type="select"
                field={@form[:jupyter].value[:virtual_size]}
                placeholder="Choose size"
                options={JupyterLabNotebook.preset_options_for_select()}
              />
            </.field>
          </.fieldset>

          <.data_list
            variant="horizontal-bolded"
            class="mt-3 mb-5"
            data={[
              {"Storage size:", Memory.humanize(@form[:jupyter].value[:storage_size].value)},
              {"Memory limits:", Memory.humanize(@form[:jupyter].value[:memory_limits].value)},
              {"CPU limits:", @form[:jupyter].value[:cpu_limits].value}
            ]}
          />

          <.flex class="justify-between w-full py-3 border-t border-gray-lighter dark:border-gray-darker" />

          <.field variant="beside">
            <:label>I need a database</:label>
            <.input type="switch" field={@form[:need_postgres]} />
          </.field>

          <div class={!normalize_value("checkbox", @form[:need_postgres].value) && "hidden"}>
            <.tab_bar variant="secondary" class="mb-6">
              <:tab
                phx-click="db_type"
                phx-value-type={:new}
                phx-target={@myself}
                selected={@db_type == :new}
              >
                New Database
              </:tab>

              <:tab
                phx-click="db_type"
                phx-value-type={:existing}
                phx-target={@myself}
                selected={@db_type == :existing}
              >
                Existing Database
              </:tab>
            </.tab_bar>

            <.input type="hidden" name="db_type" value={@db_type} />

            <.field :if={@db_type == :existing}>
              <.input
                type="select"
                field={@form[:postgres_ids]}
                placeholder="Choose a set of databases"
                options={Postgres.clusters_available_for_project()}
                multiple
              />
            </.field>

            <PostgresFormSubcomponents.size_form
              class={@db_type != :new && "hidden"}
              form={to_form(@form[:postgres].value, as: :postgres)}
              phx_target={@myself}
              with_divider={false}
              ticks={PGCluster.compact_storage_range_ticks()}
              action={:new}
            />
          </div>

          <.flex class="justify-between w-full pt-3 border-t border-gray-lighter dark:border-gray-darker" />

          <.field variant="beside">
            <:label>I need an Ollama model</:label>
            <.input type="switch" field={@form[:need_ollama]} />
          </.field>

          <div class={!normalize_value("checkbox", @form[:need_ollama].value) && "hidden"}>
            <.tab_bar variant="secondary" class="mb-6">
              <:tab
                phx-click="ollama_type"
                phx-value-type={:new}
                phx-target={@myself}
                selected={@ollama_type == :new}
              >
                New Model
              </:tab>

              <:tab
                phx-click="ollama_type"
                phx-value-type={:existing}
                phx-target={@myself}
                selected={@ollama_type == :existing}
              >
                Existing Model
              </:tab>
            </.tab_bar>

            <.input type="hidden" name="ollama_type" value={@ollama_type} />

            <.field :if={@ollama_type == :existing}>
              <.input
                type="select"
                field={@form[:ollama_ids]}
                placeholder="Choose a set of models"
                options={Ollama.model_instances_available_for_project()}
                multiple
              />
            </.field>

            <OllamaFormSubcomponents.model_form
              class={@ollama_type != :new && "hidden"}
              form={to_form(@form[:ollama].value, as: :ollama)}
              action={:new}
            />
          </div>
        </.subform>
      </.form>
    </div>
    """
  end
end
