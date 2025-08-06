defmodule ControlServerWeb.Router do
  use ControlServerWeb, :router

  import Phoenix.LiveDashboard.Router

  alias ControlServerWeb.Plug.InstallStatus

  require CommonCore.Env

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ControlServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, ControlServerWeb.CSP.new()
  end

  pipeline :auth do
    plug ControlServerWeb.Plug.SessionID
    plug InstallStatus
    plug ControlServerWeb.Plug.RefreshToken
    plug ControlServerWeb.Plug.SSOAuth
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug InstallStatus
    plug ControlServerWeb.Plug.ApiSSOAuth
  end

  # Public routes - no authentication required
  scope "/", ControlServerWeb do
    pipe_through :browser

    get "/healthz", HealthzController, :index
  end

  # SSO authentication routes - browser pipeline only
  scope "/sso", ControlServerWeb do
    pipe_through :browser

    get "/callback", SSOController, :callback
    delete "/delete", SSOController, :delete
  end

  # Main application routes - requires authentication
  scope "/", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.Home, :index
    live "/stale", Live.StaleIndex, :index
    live "/deleted_resources", Live.DeletedResourcesIndex, :index
    live "/state_summary", Live.StateSummary, :index
  end

  # Feature-specific home pages - requires authentication
  scope "/", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/magic", Live.MagicHome, :index
    live "/net_sec", Live.NetSecHome, :index
    live "/monitoring", Live.MonitoringHome, :index
    live "/devtools", Live.DevtoolsHome, :index
    live "/ai", Live.AIHome, :index
    live "/data", Live.DataHome, :index
    live "/help", Live.Help, :index
  end

  # IP Address Pool management - requires authentication
  scope "/ip_address_pools", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.IPAddressPoolIndex, :index
    live "/new", Live.IPAddressPoolNew, :index
    live "/:id/edit", Live.IPAddressPoolEdit, :index
  end

  # Deployment and snapshot management - requires authentication
  scope "/deploy", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.SnapshotApplyIndex, :index
    live "/:id/show", Live.UmbrellaSnapshotShow, :overview
    live "/:id/kube", Live.UmbrellaSnapshotShow, :kube
    live "/:id/keycloak", Live.UmbrellaSnapshotShow, :keycloak
  end

  # Battery management by group - requires authentication
  scope "/batteries", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/:group", Live.GroupBatteriesIndex
    live "/:group/new/:battery_type", Live.GroupBatteriesNew
    live "/:group/edit/:id", Live.GroupBatteriesEdit
  end

  # Project management - requires authentication
  scope "/projects", ControlServerWeb do
    pipe_through [:browser, :auth]

    # Project listing and CRUD operations
    live "/", Live.ProjectsIndex
    live "/new", Live.ProjectsNew
    live "/:id/edit", Live.ProjectsEdit
    live "/:id/timeline", Live.ProjectsTimeline
    live "/:id/snapshot", Live.ProjectsSnapshot

    # Project detail views - organized by resource type
    live "/:id/show", Live.ProjectsShow, :show
    live "/:id/pods", Live.ProjectsShow, :pods
    live "/:id/postgres_clusters", Live.ProjectsShow, :postgres_clusters
    live "/:id/redis_instances", Live.ProjectsShow, :redis_instances
    live "/:id/ferret_services", Live.ProjectsShow, :ferret_services
    live "/:id/jupyter_notebooks", Live.ProjectsShow, :jupyter_notebooks
    live "/:id/knative_services", Live.ProjectsShow, :knative_services
    live "/:id/traditional_services", Live.ProjectsShow, :traditional_services
    live "/:id/model_instances", Live.ProjectsShow, :model_instances
  end

  # Kubernetes resource management - requires authentication
  scope "/kube", ControlServerWeb do
    pipe_through [:browser, :auth]

    # Resource listing pages
    live "/deployments", Live.ResourceList, :deployment
    live "/stateful_sets", Live.ResourceList, :stateful_set
    live "/nodes", Live.ResourceList, :node
    live "/pods", Live.ResourceList, :pod
    live "/services", Live.ResourceList, :service

    # Raw resource viewing
    live "/raw/:resource_type/:name", Live.RawResource, :index
    live "/raw/:resource_type/:namespace/:name", Live.RawResource, :index

    # Pod detail views
    live "/pod/:namespace/:name/show", Live.PodShow, :index
    live "/pod/:namespace/:name/events", Live.PodShow, :events
    live "/pod/:namespace/:name/labels", Live.PodShow, :labels
    live "/pod/:namespace/:name/annotations", Live.PodShow, :annotations
    live "/pod/:namespace/:name/security", Live.PodShow, :security
    live "/pod/:namespace/:name/logs", Live.PodShow, :logs

    # Deployment detail views
    live "/deployment/:namespace/:name/show", Live.DeploymentShow, :index
    live "/deployment/:namespace/:name/events", Live.DeploymentShow, :events
    live "/deployment/:namespace/:name/pods", Live.DeploymentShow, :pods
    live "/deployment/:namespace/:name/labels", Live.DeploymentShow, :labels
    live "/deployment/:namespace/:name/annotations", Live.DeploymentShow, :annotations

    # StatefulSet detail views
    live "/stateful_set/:namespace/:name/show", Live.StatefulSetShow, :index
    live "/stateful_set/:namespace/:name/events", Live.StatefulSetShow, :events
    live "/stateful_set/:namespace/:name/pods", Live.StatefulSetShow, :pods
    live "/stateful_set/:namespace/:name/labels", Live.StatefulSetShow, :labels
    live "/stateful_set/:namespace/:name/annotations", Live.StatefulSetShow, :annotations

    # Service detail views
    live "/service/:namespace/:name/show", Live.ServiceShow
  end

  # Redis cluster management - requires authentication
  scope "/redis", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.RedisIndex, :index
    live "/new", Live.RedisNew, :new
    live "/:id/edit", Live.RedisEdit, :edit
    live "/:id/show", Live.RedisShow, :show
    live "/:id/services", Live.RedisShow, :services
  end

  # PostgreSQL cluster management - requires authentication
  scope "/postgres", ControlServerWeb do
    pipe_through [:browser, :auth]

    # Main CRUD operations
    live "/", Live.PostgresIndex, :index
    live "/new", Live.PostgresNew, :new
    live "/:id/edit", Live.PostgresEdit, :edit

    # Cluster detail views
    live "/:id/show", Live.PostgresShow, :show
    live "/:id/events", Live.PostgresShow, :events
    live "/:id/pods", Live.PostgresShow, :pods
    live "/:id/users", Live.PostgresShow, :users
    live "/:id/services", Live.PostgresShow, :services
    live "/:id/edit_versions", Live.PostgresShow, :edit_versions
    live "/:id/backups", Live.PostgresShow, :backups
  end

  # FerretDB service management - requires authentication
  scope "/ferretdb", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.FerretServiceIndex, :index
    live "/new", Live.FerretServiceNew, :show
    live "/:id/edit", Live.FerretServiceEdit, :show
    live "/:id/show", Live.FerretServiceShow, :show
    live "/:id/pods", Live.FerretServiceShow, :pods
    live "/:id/edit_versions", Live.FerretServiceShow, :edit_versions
  end

  # Jupyter notebook management - requires authentication
  scope "/notebooks", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.JupyterLabNotebookIndex, :index
    live "/new", Live.JupyterLabNotebookNew, :new
    live "/:id", Live.JupyterLabNotebookShow, :show
    live "/:id/edit", Live.JupyterLabNotebookEdit, :edit
  end

  # Knative service management - requires authentication
  scope "/knative", ControlServerWeb do
    pipe_through [:browser, :auth]

    # Main CRUD operations
    live "/services", Live.KnativeIndex, :index
    live "/services/new", Live.KnativeNew, :new
    live "/services/:id/edit", Live.KnativeEdit, :edit

    # Service detail views
    live "/services/:id/show", Live.KnativeShow, :show
    live "/services/:id/events", Live.KnativeShow, :events
    live "/services/:id/pods", Live.KnativeShow, :pods
    live "/services/:id/deployments", Live.KnativeShow, :deployments
    live "/services/:id/edit_versions", Live.KnativeShow, :edit_versions
  end

  # Traditional service management - requires authentication
  scope "/traditional_services", ControlServerWeb do
    pipe_through [:browser, :auth]

    # Main CRUD operations
    live "/", Live.TraditionalServicesIndex, :index
    live "/new", Live.TraditionalServicesNew, :new
    live "/:id/edit", Live.TraditionalServicesEdit, :edit

    # Service detail views
    live "/:id/show", Live.TraditionalServicesShow, :show
    live "/:id/edit_versions", Live.TraditionalServicesShow, :edit_versions
    live "/:id/events", Live.TraditionalServicesShow, :events
    live "/:id/pods", Live.TraditionalServicesShow, :pods
  end

  # Security and vulnerability reporting - requires authentication
  scope "/trivy_reports", ControlServerWeb do
    pipe_through [:browser, :auth]

    # Report type listing pages
    live "/config_audit_report", Live.TrivyReportsIndex, :aqua_config_audit_report
    live "/cluster_rbac_assessment_report", Live.TrivyReportsIndex, :aqua_cluster_rbac_assessment_report
    live "/rbac_assessment_report", Live.TrivyReportsIndex, :aqua_rbac_assessment_report
    live "/infra_assessment_report", Live.TrivyReportsIndex, :aqua_infra_assessment_report
    live "/vulnerability_report", Live.TrivyReportsIndex, :aqua_vulnerability_report

    # Individual report viewing
    live "/:resource_type/:namespace/:name", Live.TrivyReportShow, :show
  end

  # gateway management - requires authentication
  scope "/gateway", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/routes", Live.GatewayRoutesIndex, :index
    live "/route/:kind/:namespace/:name", Live.GatewayRouteShow, :index
  end

  # Keycloak identity management - requires authentication
  scope "/keycloak", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/realms", Live.KeycloakRealmsList
    live "/realm/:name", Live.KeycloakRealm
  end

  # AI model instance management - requires authentication
  scope "/model_instances", ControlServerWeb do
    pipe_through [:browser, :auth]

    # Main CRUD operations
    live "/", Live.OllamaModelInstancesIndex
    live "/new", Live.OllamaModelInstanceNew
    live "/:id/edit", Live.OllamaModelInstanceEdit

    # Instance detail views
    live "/:id/show", Live.OllamaModelInstanceShow, :show
    live "/:id/pods", Live.OllamaModelInstanceShow, :pods
    live "/:id/services", Live.OllamaModelInstanceShow, :services
    live "/:id/edit_versions", Live.OllamaModelInstanceShow, :edit_versions
  end

  # System history and audit - requires authentication
  scope "/history", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/timeline", Live.Timeline, :index
  end

  # Version management and content addressing - requires authentication
  scope "/edit_versions", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.EditVersionsList, :index
    live "/:id", Live.EditVersionShow, :show
  end

  scope "/content_addressable", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.ContentAddressableIndex, :index
  end

  # REST API endpoints - requires API authentication
  scope "/api", ControlServerWeb do
    pipe_through :api

    # Database cluster management
    resources "/postgres/clusters", ClusterController, except: [:new, :edit]
    resources "/redis/clusters", RedisInstanceController, except: [:new, :edit]

    # Service management
    resources "/knative/services", KnativeServiceController, except: [:new, :edit]
    resources "/traditional_services", TraditionalServicesController, except: [:new, :edit]

    # Notebook management
    resources "/notebooks/jupyter_lab_notebooks", JupyterLabNotebookController, except: [:new, :edit]
  end

  # Development tools - only available in development environment
  if CommonCore.Env.dev_env?() do
    scope "/dev" do
      pipe_through :browser

      # Phoenix LiveDashboard for development metrics and debugging
      live_dashboard "/dashboard", metrics: ControlServerWeb.Telemetry
    end
  end
end
