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

  scope "/", ControlServerWeb do
    pipe_through :browser

    get "/sso/callback", SSOController, :callback
    delete "/sso/delete", SSOController, :delete
  end

  scope "/", ControlServerWeb do
    pipe_through :browser

    get "/healthz", HealthzController, :index
  end

  scope "/", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.Home, :index
    live "/stale", Live.StaleIndex, :index
    live "/deleted_resources", Live.DeletedResourcesIndex, :index
    live "/state_summary", Live.StateSummary, :index

    # Homes
    live "/magic", Live.MagicHome, :index
    live "/net_sec", Live.NetSecHome, :index
    live "/monitoring", Live.MonitoringHome, :index
    live "/devtools", Live.DevtoolsHome, :index
    live "/ai", Live.AIHome, :index
    live "/data", Live.DataHome, :index
    live "/help", Live.Help, :index
  end

  scope "/ip_address_pools", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.IPAddressPoolIndex, :index
    live "/new", Live.IPAddressPoolNew, :index
    live "/:id/edit", Live.IPAddressPoolEdit, :index
  end

  scope "/deploy", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.SnapshotApplyIndex, :index
    live "/:id/show", Live.UmbrellaSnapshotShow, :index
    live "/:umbrella_id/kube/:id", Live.KubeSnapshotShow, :index
    live "/:umbrella_id/keycloak/:id", Live.KeycloakSnapshotShow, :index
  end

  scope "/batteries", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/:group", Live.GroupBatteriesIndex
    live "/:group/new/:battery_type", Live.GroupBatteriesNew
    live "/:group/edit/:id", Live.GroupBatteriesEdit
  end

  scope "/projects", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.ProjectsIndex
    live "/new", Live.ProjectsNew
    live "/:id", Live.ProjectsShow
    live "/:id/edit", Live.ProjectsEdit
    live "/:id/timeline", Live.ProjectsTimeline
  end

  scope "/kube", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/deployments", Live.ResourceList, :deployment
    live "/stateful_sets", Live.ResourceList, :stateful_set
    live "/nodes", Live.ResourceList, :node
    live "/pods", Live.ResourceList, :pod
    live "/services", Live.ResourceList, :service

    live "/raw/:resource_type/:name", Live.RawResource, :index
    live "/raw/:resource_type/:namespace/:name", Live.RawResource, :index

    live "/pod/:namespace/:name/events", Live.PodShow, :events
    live "/pod/:namespace/:name/labels", Live.PodShow, :labels
    live "/pod/:namespace/:name/annotations", Live.PodShow, :annotations
    live "/pod/:namespace/:name/security", Live.PodShow, :security
    live "/pod/:namespace/:name/logs", Live.PodShow, :logs
    live "/pod/:namespace/:name/show", Live.PodShow, :index

    live "/deployment/:namespace/:name/show", Live.DeploymentShow
    live "/stateful_set/:namespace/:name/show", Live.StatefulSetShow
    live "/service/:namespace/:name/show", Live.ServiceShow
  end

  scope "/redis", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.RedisIndex, :index
    live "/new", Live.RedisNew, :new
    live "/:id/edit", Live.RedisEdit, :edit
    live "/:id/show", Live.RedisShow, :show
    live "/:id/services", Live.RedisShow, :services
  end

  scope "/postgres", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.PostgresIndex, :index
    live "/new", Live.PostgresNew, :new
    live "/:id/edit", Live.PostgresEdit, :edit
    live "/:id/show", Live.PostgresShow, :show
    live "/:id/events", Live.PostgresShow, :events
    live "/:id/pods", Live.PostgresShow, :pods
    live "/:id/users", Live.PostgresShow, :users
    live "/:id/services", Live.PostgresShow, :services
    live "/:id/edit_versions", Live.PostgresShow, :edit_versions
  end

  scope "/ferretdb", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.FerretServiceIndex, :index
    live "/:id/edit", Live.FerretServiceEdit, :show
    live "/new", Live.FerretServiceNew, :show

    live "/:id/show", Live.FerretServiceShow, :show
    live "/:id/edit_versions", Live.FerretServiceShow, :edit_versions
  end

  scope "/notebooks", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.JupyterLabNotebookIndex, :index
    live "/new", Live.JupyterLabNotebookNew, :new
    live "/:id", Live.JupyterLabNotebookShow, :show
    live "/:id/edit", Live.JupyterLabNotebookEdit, :edit
  end

  scope "/knative", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/services", Live.KnativeIndex, :index
    live "/services/new", Live.KnativeNew, :new

    live "/services/:id/edit", Live.KnativeEdit, :edit
    live "/services/:id/show", Live.KnativeShow, :show
    live "/services/:id/events", Live.KnativeShow, :events
    live "/services/:id/pods", Live.KnativeShow, :pods
    live "/services/:id/deployments", Live.KnativeShow, :deployments
    live "/services/:id/edit_versions", Live.KnativeShow, :edit_versions
  end

  scope "/traditional_services", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.TraditionalServicesIndex, :index
    live "/new", Live.TraditionalServicesNew, :new
    live "/:id/edit", Live.TraditionalServicesEdit, :edit

    live "/:id/show", Live.TraditionalServicesShow, :show
    live "/:id/edit_versions", Live.TraditionalServicesShow, :edit_versions
    live "/:id/events", Live.TraditionalServicesShow, :events
    live "/:id/pods", Live.TraditionalServicesShow, :pods
  end

  scope "/trivy_reports", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/config_audit_report", Live.TrivyReportsIndex, :aqua_config_audit_report

    live "/cluster_rbac_assessment_report",
         Live.TrivyReportsIndex,
         :aqua_cluster_rbac_assessment_report

    live "/rbac_assessment_report", Live.TrivyReportsIndex, :aqua_rbac_assessment_report

    live "/infra_assessment_report", Live.TrivyReportsIndex, :aqua_infra_assessment_report

    live "/vulnerability_report", Live.TrivyReportsIndex, :aqua_vulnerability_report

    live "/:resource_type/:namespace/:name", Live.TrivyReportShow, :show
  end

  scope "/istio", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/virtual_services", Live.IstioVirtualServicesIndex, :index
    live "/virtual_service/:namespace/:name", Live.IstioVirtualServiceShow, :index
  end

  scope "/keycloak", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/realms", Live.KeycloakRealmsList
    live "/realm/:name", Live.KeycloakRealm
  end

  scope "/model_instances", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.OllamaModelInstancesIndex
    live "/new", Live.OllamaModelInstanceNew
    live "/:id/edit", Live.OllamaModelInstanceEdit
    live "/:id/show", Live.OllamaModelInstanceShow
  end

  scope "/history", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/timeline", Live.Timeline, :index
  end

  scope "/edit_versions", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.EditVersionsList, :index
    live "/:id", Live.EditVersionShow, :show
  end

  scope "/content_addressable", ControlServerWeb do
    pipe_through [:browser, :auth]

    live "/", Live.ContentAddressableIndex, :index
  end

  scope "/api", ControlServerWeb do
    pipe_through :api

    resources "/postgres/clusters", ClusterController, except: [:new, :edit]
    resources "/redis/clusters", RedisInstanceController, except: [:new, :edit]
    resources "/knative/services", KnativeServiceController, except: [:new, :edit]
    resources "/traditional_services", TraditionalServicesController, except: [:new, :edit]
    resources "/notebooks/jupyter_lab_notebooks", JupyterLabNotebookController, except: [:new, :edit]
  end

  if CommonCore.Env.dev_env?() do
    # Enables LiveDashboard only for development
    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ControlServerWeb.Telemetry
    end
  end
end
