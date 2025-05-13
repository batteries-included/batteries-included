defmodule ControlServerWeb.Live.ProjectsNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Containers.EnvValue
  alias CommonCore.Defaults.Namespaces
  alias CommonCore.Postgres.Cluster, as: PGCluster
  alias CommonCore.Redis.RedisInstance, as: RedisCluster
  alias CommonCore.StateSummary.PostgresState
  alias ControlServer.Batteries
  alias ControlServer.Batteries.Installer
  alias ControlServer.FerretDB
  alias ControlServer.Knative
  alias ControlServer.Notebooks
  alias ControlServer.Ollama
  alias ControlServer.Postgres
  alias ControlServer.Projects
  alias ControlServer.Redis
  alias ControlServer.TraditionalServices
  alias ControlServerWeb.Projects.AIForm
  alias ControlServerWeb.Projects.BatteriesForm
  alias ControlServerWeb.Projects.DatabaseForm
  alias ControlServerWeb.Projects.ImportForm
  alias ControlServerWeb.Projects.ProjectForm
  alias ControlServerWeb.Projects.WebForm
  alias KubeServices.SystemState.SummaryStorage

  require Logger

  @root_pg_user "root"

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    # Allow the back button to be dynamic and go back steps
    return_to = Map.get(params, "return_to", ~p"/projects")
    back_click = JS.push("back", value: %{return_to: return_to})

    {:ok,
     socket
     |> assign(:installing, false)
     |> assign(:back_click, back_click)
     |> assign(:steps, steps())
     |> assign(:current_step, List.first(steps()))
     |> assign(:form_data, %{})
     |> assign(:batteries, Batteries.list_system_batteries())
     |> assign(:page_title, "Start Your Project")}
  end

  # Moves back to the previous step, or navigates to the `return_to` URL query if on the first
  # step. This allows the back button to be dynamic and either move steps or do a live navigation.
  @impl Phoenix.LiveView
  def handle_event("back", params, socket) do
    prev_index = Enum.find_index(socket.assigns.steps, &(&1 == socket.assigns.current_step)) - 1
    prev_step = Enum.at(socket.assigns.steps, prev_index)

    if prev_step && prev_index >= 0 do
      {:noreply, assign(socket, :current_step, prev_step)}
    else
      {:noreply, push_navigate(socket, to: params["return_to"])}
    end
  end

  # Updates the project steps when the type changes in the new project subform.
  # It also resets the form data so we don't create resources from a previously-selected type.
  @impl Phoenix.LiveView
  def handle_info({:project_type, project_type}, socket) do
    {:noreply,
     socket
     |> assign(:form_data, %{})
     |> assign(:steps, steps(project_type))}
  end

  # Moves to the next step when sub-forms are submitted. This will store the sub-form data in the
  # assigns until the end of the new project flow, when all the resources will be created at once.
  @impl Phoenix.LiveView
  def handle_info({:next, {step, step_data}}, socket) do
    form_data = Map.put(socket.assigns.form_data, step, step_data)
    next_index = Enum.find_index(socket.assigns.steps, &(&1 == step)) + 1

    if next_step = Enum.at(socket.assigns.steps, next_index) do
      # There are still more steps in the flow, save form data and move to next step
      {:noreply,
       socket
       |> assign(:form_data, form_data)
       |> assign(:current_step, next_step)}
    else
      # There are no more steps in the flow, go ahead and create all the resources
      install_batteries(form_data[BatteriesForm])

      {:noreply,
       socket
       |> assign(:installing, true)
       |> assign(:form_data, form_data)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:async_installer, {:install_complete, _}}, socket) do
    # Pause for a moment to make sure the sexy loader is shown
    Process.sleep(1000)

    form_data = socket.assigns.form_data

    with {:ok, project} <- Projects.create_project(form_data[ProjectForm]),
         {:ok, db_pg} <- create_postgres(project, form_data[DatabaseForm]),
         {:ok, _db_redis} <- create_redis(project, form_data[DatabaseForm]),
         {:ok, _db_ferret} <- create_ferret(project, form_data[DatabaseForm], db_pg),
         {:ok, ai_pg} <- create_postgres(project, form_data[AIForm]),
         {:ok, _ai_ollama} <- create_ollama(project, form_data[AIForm]),
         {:ok, _ai_notebook} <- create_jupyter(project, form_data[AIForm], ai_pg),
         {:ok, web_pg} <- create_postgres(project, form_data[WebForm]),
         {:ok, web_redis} <- create_redis(project, form_data[WebForm]),
         {:ok, _web_knative} <- create_knative(project, form_data[WebForm], web_pg, web_redis),
         {:ok, _web_traditional} <- create_traditional(project, form_data[WebForm], web_pg, web_redis) do
      {:noreply, push_navigate(socket, to: ~p"/projects/#{project.id}/show")}
    else
      err ->
        # This should never be reached since form validation happens
        # in each step, and you can't move on until they are valid.
        # Keep this as a failsafe just in case something sneaks through.
        Logger.error(err)

        {:noreply,
         socket
         |> assign(:installing, false)
         |> put_flash(:global_error, "Could not create all the project resources")}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({:async_installer, _}, socket), do: {:noreply, socket}

  defp install_batteries(data) do
    KubeServices.SnapshotApply.Worker.start()

    data
    |> Enum.map(fn {key, _} ->
      key
      |> String.to_existing_atom()
      |> Catalog.get()
      |> CatalogBattery.to_fresh_args()
    end)
    |> Installer.install_all(update_target: self())
  end

  defp create_postgres(project, %{"postgres" => postgres_data} = data) do
    users = generate_postgres_users(data)

    postgres_data
    |> Map.merge(%{
      "project_id" => project.id,
      "users" => users,
      "database" => %{"name" => "app", "owner" => @root_pg_user}
    })
    |> Map.put_new("storage_class", get_default_storage_class())
    |> Postgres.create_cluster()
  end

  defp create_postgres(project, %{"postgres_ids" => postgres_ids} = data) do
    results =
      Enum.map(postgres_ids, fn id ->
        cluster = Postgres.get_cluster!(id)
        users = cluster.users ++ generate_postgres_users(data)

        Postgres.update_cluster(cluster, %{project_id: project.id, users: users})
      end)

    if Enum.all?(results, fn {status, _} -> status == :ok end) do
      {:ok, results}
    else
      {:error, results}
    end
  end

  defp create_postgres(_project, _postgres_data), do: {:ok, nil}

  defp create_redis(project, %{"redis" => redis_data}) do
    redis_data
    |> Map.put("project_id", project.id)
    |> Redis.create_redis_instance()
  end

  defp create_redis(_project, _redis_data), do: {:ok, nil}

  defp create_ferret(project, %{"ferret" => ferret_data}, %PGCluster{} = pg) do
    ferret_data
    |> Map.put("project_id", project.id)
    |> Map.put("postgres_cluster_id", pg.id)
    |> FerretDB.create_ferret_service()
  end

  defp create_ferret(_project, _ferret_data, _pg), do: {:ok, nil}

  defp create_ollama(project, %{"ollama" => ollama_data}) do
    ollama_data
    |> Map.put("project_id", project.id)
    |> Ollama.create_model_instance()
  end

  defp create_ollama(_project, _ollama_data), do: {:ok, nil}

  defp create_jupyter(project, %{"jupyter" => jupyter_data}, pg) do
    jupyter_data
    |> Map.put("project_id", project.id)
    |> Map.put("env_values", database_env_values(pg, "jupyter"))
    |> Map.put_new("storage_class", get_default_storage_class())
    |> Notebooks.create_jupyter_lab_notebook()
  end

  defp create_jupyter(_project, _jupyter_data, _pg), do: {:ok, nil}

  defp create_knative(project, %{"knative" => knative_data}, pg, redis) do
    knative_data
    |> Map.put("project_id", project.id)
    |> Map.put("env_values", database_env_values(pg, "knative") ++ redis_env_values(redis))
    |> Knative.create_service()
  end

  defp create_knative(_project, _knative_data, _pg, _redis), do: {:ok, nil}

  defp create_traditional(project, %{"traditional" => traditional_data}, pg, redis) do
    traditional_data
    |> Map.put("project_id", project.id)
    |> Map.put("env_values", database_env_values(pg, "traditional") ++ redis_env_values(redis))
    |> TraditionalServices.create_service()
  end

  defp create_traditional(_project, _traditional_data, _pg, _redis), do: {:ok, nil}

  defp database_env_values(clusters, username) when is_list(clusters) do
    clusters
    |> Enum.with_index()
    |> Enum.map(fn {{:ok, %PGCluster{users: users} = pg}, index} ->
      user = get_postgres_user(users, username)

      %EnvValue{
        name: if(Enum.count(clusters) > 1, do: "DATABASE_URL_#{index + 1}", else: "DATABASE_URL"),
        source_type: :secret,
        source_name: PostgresState.user_secret(%{}, pg, user),
        source_key: "dsn"
      }
    end)
  end

  defp database_env_values(%PGCluster{users: users} = pg, username) do
    user = get_postgres_user(users, username)

    [
      %EnvValue{
        name: "DATABASE_URL",
        source_type: :secret,
        source_name: PostgresState.user_secret(%{}, pg, user),
        source_key: "dsn"
      }
    ]
  end

  defp database_env_values(_pg, _username), do: []

  defp redis_env_values(%RedisCluster{} = _redis) do
    [
      # TODO: Get a dsn or similar value for the Redis cluster
      #
      # %EnvValue{
      #   name: "REDIS_URL",
      #   source_type: :secret,
      #   source_name: "",
      #   source_key: "dsn"
      # }
    ]
  end

  defp redis_env_values(_), do: []

  defp generate_postgres_users(data) do
    data
    |> Enum.map(fn {key, _} ->
      case key do
        "postgres" ->
          %{
            "username" => @root_pg_user,
            "roles" => ["login", "superuser"],
            "credential_namespaces" => [Namespaces.core()]
          }

        "jupyter" ->
          %{
            "username" => "jupyter",
            "roles" => ["login"],
            "credential_namespaces" => [Namespaces.ai()]
          }

        "knative" ->
          %{
            "username" => "knative",
            "roles" => ["login"],
            "credential_namespaces" => [Namespaces.knative()]
          }

        "traditional" ->
          %{
            "username" => "traditional",
            "roles" => ["login"],
            "credential_namespaces" => [Namespaces.traditional()]
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp get_postgres_user(users, username) do
    Enum.find(users, &(Map.get(&1, :username) == username))
  end

  defp get_default_storage_class do
    case SummaryStorage.default_storage_class() do
      nil ->
        nil

      storage_class ->
        get_in(storage_class, ["metadata", "name"])
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full gap-8">
      <.page_header title="Start Your Project" back_click={@back_click} class="mb-0" />

      <.progress
        variant="stepped"
        total={Enum.count(@steps)}
        current={Enum.find_index(@steps, &(&1 == @current_step)) + 1}
      />

      <div class="flex-1 relative">
        <.flash_group flash={@flash} />

        <.live_component
          id="project-form"
          module={ProjectForm}
          class={subform_class(@current_step, ProjectForm)}
        />

        <.live_component
          id="project-web-form"
          module={WebForm}
          class={subform_class(@current_step, WebForm)}
        />

        <.live_component
          id="project-ai-form"
          module={AIForm}
          class={subform_class(@current_step, AIForm)}
        />

        <.live_component
          id="project-database-form"
          module={DatabaseForm}
          class={subform_class(@current_step, DatabaseForm)}
        />

        <.live_component
          id="project-import-form"
          module={ImportForm}
          class={subform_class(@current_step, ImportForm)}
        />

        <.live_component
          id="project-batteries-form"
          module={BatteriesForm}
          class={subform_class(@current_step, BatteriesForm)}
          data={@form_data}
          installed={@batteries}
        />
      </div>

      <.loader :if={@installing} fullscreen />

      <.modal id="demo-video-modal" size="lg" class="p-2 pt-4">
        <:title>Demo Video</:title>

        <.video
          src="https://www.youtube.com/embed/dQw4w9WgXcQ?si=UZCUB2JKWZe3_5Uw"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          referrerpolicy="strict-origin-when-cross-origin"
          allowfullscreen
        />
      </.modal>
    </div>
    """
  end

  defp subform_class(step, subform), do: ["h-full", step != subform && "hidden"]

  # Defines the ordering of the new project subform flow

  defp steps(type) when is_binary(type), do: type |> String.to_existing_atom() |> steps()
  defp steps(:web), do: [ProjectForm, WebForm, BatteriesForm]
  defp steps(:ai), do: [ProjectForm, AIForm, BatteriesForm]
  defp steps(:db), do: [ProjectForm, DatabaseForm, BatteriesForm]
  defp steps(:import), do: [ProjectForm, ImportForm, BatteriesForm]
  defp steps(:bare), do: [ProjectForm, BatteriesForm]
  defp steps, do: steps(:bare)
end
