defmodule ControlServerWeb.Router do
  use ControlServerWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ControlServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, ControlServerWeb.CSP.new()
    plug KubeServices.ET.StatusPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ControlServerWeb do
    pipe_through :browser

    live "/", Live.Home, :index
    live "/stale", Live.StaleIndex, :index
    live "/deleted_resources", Live.DeletedResourcesIndex, :index

    # Homes
    live "/magic", Live.MagicHome, :index
    live "/net_sec", Live.NetSecHome, :index
    live "/monitoring", Live.MonitoringHome, :index
    live "/devtools", Live.DevtoolsHome, :index
    live "/ai", Live.AIHome, :index
    live "/data", Live.DataHome, :index
  end

  scope "/ip_address_pools", ControlServerWeb do
    pipe_through :browser

    live "/", Live.IPAddressPoolIndex, :index
    live "/new", Live.IPAddressPoolNew, :index
    live "/:id/edit", Live.IPAddressPoolEdit, :index
  end

  scope "/deploy", ControlServerWeb do
    pipe_through :browser

    live "/", Live.SnapshotApplyIndex, :index
    live "/:id/show", Live.UmbrellaSnapshotShow, :index
    live "/:umbrella_id/kube/:id", Live.KubeSnapshotShow, :index
    live "/:umbrella_id/keycloak/:id", Live.KeycloakSnapshotShow, :index
  end

  scope "/batteries", ControlServerWeb.GroupBatteries do
    pipe_through :browser

    live "/:group", IndexLive
    live "/:group/new/:battery_type", NewLive
    live "/:group/edit/:battery_type", EditLive
  end

  scope "/projects", ControlServerWeb.Projects do
    pipe_through :browser

    live "/", IndexLive
    live "/new", NewLive
    live "/:id", ShowLive
    live "/:id/edit", EditLive
    live "/:id/timeline", TimelineLive
  end

  scope "/kube", ControlServerWeb do
    pipe_through :browser

    live "/deployments", Live.ResourceList, :deployment
    live "/stateful_sets", Live.ResourceList, :stateful_set
    live "/nodes", Live.ResourceList, :node
    live "/pods", Live.ResourceList, :pod
    live "/services", Live.ResourceList, :service

    live "/raw/:resource_type/:namespace/:name", Live.RawResource, :index

    live "/pod/:namespace/:name/events", PodLive.Show, :events
    live "/pod/:namespace/:name/labels", PodLive.Show, :labels
    live "/pod/:namespace/:name/security", PodLive.Show, :security
    live "/pod/:namespace/:name/logs", PodLive.Show, :logs
    live "/pod/:namespace/:name/show", PodLive.Show, :index

    live "/deployment/:namespace/:name/show", DeploymentLive.Show
    live "/stateful_set/:namespace/:name/show", StatefulSetLive.Show
    live "/service/:namespace/:name/show", ServiceLive.Show
  end

  scope "/redis", ControlServerWeb do
    pipe_through :browser

    live "/", Live.Redis, :index
    live "/new", Live.RedisNew, :new
    live "/:id/edit", Live.RedisEdit, :edit
    live "/:id/show", Live.RedisShow, :show
    live "/:id/services", Live.RedisShow, :services
  end

  scope "/postgres", ControlServerWeb do
    pipe_through :browser

    live "/", Live.PostgresClusters, :index
    live "/new", Live.PostgresNew, :new
    live "/:id/edit", Live.PostgresEdit, :edit
    live "/:id/show", Live.PostgresShow, :show
    live "/:id/users", Live.PostgresShow, :users
    live "/:id/services", Live.PostgresShow, :services
    live "/:id/edit_versions", Live.PostgresShow, :edit_versions
  end

  scope "/ferretdb", ControlServerWeb do
    pipe_through :browser

    live "/", Live.FerretServiceIndex, :index
    live "/:id/edit", Live.FerretServiceEdit, :show
    live "/new", Live.FerretServiceNew, :show

    live "/:id/show", Live.FerretServiceShow, :show
    live "/:id/edit_versions", Live.FerretServiceShow, :edit_versions
  end

  scope "/notebooks", ControlServerWeb do
    pipe_through :browser

    live "/", Live.JupyterLabNotebookIndex, :index
    live "/new", Live.JupyterLabNotebookNew, :new
    live "/:id", Live.JupyterLabNotebookShow, :show
    live "/:id/edit", Live.JupyterLabNotebookEdit, :edit
  end

  scope "/knative", ControlServerWeb do
    pipe_through :browser

    live "/services", Live.KnativeServicesIndex, :index
    live "/services/new", Live.KnativeNew, :new
    live "/services/:id/edit", Live.KnativeEdit, :edit
    live "/services/:id/show", Live.KnativeShow, :show
    live "/services/:id/env_vars", Live.KnativeShow, :env_vars
    live "/services/:id/edit_versions", Live.KnativeShow, :edit_versions
  end

  scope "/traditional_services", ControlServerWeb do
    pipe_through :browser

    live "/", Live.TraditionalServicesIndex, :index
    live "/new", Live.TraditionalServicesNew, :new
    live "/:id/edit", Live.TraditionalServicesEdit, :edit
    live "/:id/show", Live.TraditionalServicesShow, :show
  end

  scope "/trivy_reports", ControlServerWeb do
    pipe_through :browser

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
    pipe_through :browser

    live "/virtual_services", Live.IstioVirtualServicesIndex, :index
    live "/virtual_service/:namespace/:name", Live.IstioVirtualServiceShow, :index
  end

  scope "/keycloak", ControlServerWeb do
    pipe_through :browser

    live "/realms", Live.KeycloakRealmsList
    live "/realm/:name", Live.KeycloakRealm
  end

  scope "/history", ControlServerWeb do
    pipe_through :browser

    live "/timeline", Live.Timeline, :index
  end

  scope "/edit_versions", ControlServerWeb do
    pipe_through :browser
    live "/", Live.EditVersionsList, :index
    live "/:id", Live.EditVersionShow, :show
  end

  scope "/content_addressable", ControlServerWeb do
    pipe_through :browser

    live "/", Live.ContentAddressableIndex, :index
  end

  scope "/api", ControlServerWeb do
    pipe_through :api

    get "/system_state", SystemStateController, :index
    resources "/postgres/clusters", ClusterController, except: [:new, :edit]
    resources "/redis/clusters", FailoverClusterController, except: [:new, :edit]
    resources "/knative/services", KnativeServiceController, except: [:new, :edit]
    resources "/traditional_services", TraditionalServicesController, except: [:new, :edit]
    resources "/notebooks/jupyter_lab_notebooks", JupyterLabNotebookController, except: [:new, :edit]
  end

  if Enum.member?([:dev, :test], Mix.env()) do
    # Enables LiveDashboard only for development
    scope "/dev" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ControlServerWeb.Telemetry
    end
  end
end
