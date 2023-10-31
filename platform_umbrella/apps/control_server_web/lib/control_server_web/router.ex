defmodule ControlServerWeb.Router do
  use ControlServerWeb, :router

  import Phoenix.LiveDashboard.Router
  import PhoenixStorybook.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ControlServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, ControlServerWeb.CSP.new()
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ControlServerWeb do
    pipe_through :browser
    live "/", Live.Home, :index
    live "/notebooks", Live.JupyterLabNotebookIndex, :index
    live "/stale", Live.StaleIndex, :index
    live "/deleted_resources", Live.DeletedResourcesIndex, :index

    # Homes
    live "/magic", Live.MagicHome, :index
    live "/net_sec", Live.NetSecHome, :index
    live "/monitoring", Live.MonitoringHome, :index
    live "/devtools", Live.DevtoolsHome, :index
    live "/ml", Live.MLHome, :index
    live "/data", Live.DataHome, :index
  end

  scope "/ip_address_pools", ControlServerWeb do
    pipe_through :browser

    live "/", Live.IPAddressPoolIndex, :index
    live "/new", Live.IPAddressPoolNew, :index
    live "/:id/show", Live.IPAddressPoolShow, :index
    live "/:id/edit", Live.IPAddressPoolEdit, :index
  end

  scope "/snapshot_apply", ControlServerWeb do
    pipe_through :browser

    live "/", Live.SnapshotApplyIndex, :index
    live "/:id/show", Live.KubeSnapshotShow, :index
  end

  scope "/system_batteries", ControlServerWeb do
    pipe_through :browser

    live "/", Live.SystemBatteryIndex, :index
    live "/:id", Live.SystemBatteryShow, :show
  end

  scope "/batteries", ControlServerWeb do
    pipe_through :browser

    live "/:group", Live.GroupBatteries, :show
    live "/:group/install/:battery_type", Live.GroupBatteries, :install
  end

  scope "/system_projects", ControlServerWeb do
    pipe_through :browser

    live "/", Live.SystemProjectIndex, :index
    live "/new", Live.SystemProjectNew, :index
    live "/:id/edit", Live.SystemProjectEdit, :edit
    live "/:id/show", Live.SystemProjectShow, :show
  end

  scope "/kube", ControlServerWeb do
    pipe_through :browser

    live "/deployments", Live.ResourceList, :deployment
    live "/stateful_sets", Live.ResourceList, :stateful_set
    live "/nodes", Live.ResourceList, :node
    live "/pods", Live.ResourceList, :pod
    live "/services", Live.ResourceList, :service

    live "/raw/:resource_type/:namespace/:name", Live.RawResource, :index
    live "/:resource_type/:namespace/:name", Live.ResourceInfo, :index
  end

  scope "/redis", ControlServerWeb do
    pipe_through :browser

    live "/", Live.Redis, :index
    live "/new", Live.RedisNew, :new
    live "/:id/edit", Live.RedisEdit, :edit
    live "/:id/show", Live.RedisShow, :show
  end

  scope "/postgres", ControlServerWeb do
    pipe_through :browser

    live "/", Live.PostgresClusters, :index
    live "/new", Live.PostgresNew, :new
    live "/:id/edit", Live.PostgresEdit, :edit
    live "/:id/show", Live.PostgresShow, :show
  end

  scope "/ceph", ControlServerWeb do
    pipe_through :browser

    live "/", Live.CephIndex, :index
    live "/clusters/new", Live.CephClusterNew, :new
    live "/clusters/:id/edit", Live.CephClusterEdit, :edit
    live "/clusters/:id/show", Live.CephClusterShow, :show
    live "/filesystems/new", Live.CephFilesystemNew, :new
    live "/filesystems/:id/edit", Live.CephFilesystemEdit, :edit
    live "/filesystems/:id/show", Live.CephFilesystemShow, :show
  end

  scope "/knative", ControlServerWeb do
    pipe_through :browser

    live "/services", Live.KnativeServicesIndex, :index
    live "/services/new", Live.KnativeNew, :new
    live "/services/:id/edit", Live.KnativeEdit, :edit
    live "/services/:id/show", Live.KnativeShow, :show
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

  scope "/keycloak", ControlServerWeb do
    pipe_through :browser

    live "/realms", Live.KeycloakRealmsList
    live "/realm/:name", Live.KeycloakRealm
  end

  scope "/history", ControlServerWeb do
    pipe_through :browser

    live "/timeline", Live.Timeline, :index
    live "/edit_versions", Live.EditVersionsList, :index
  end

  scope "/content_addressable", ControlServerWeb do
    pipe_through :browser

    live "/", Live.ContentAddressableIndex, :index
  end

  scope "/api", ControlServerWeb do
    pipe_through :api

    get "/system_state", SystemStateController, :index
  end

  if Enum.member?([:dev, :test], Mix.env()) do
    # Enables LiveDashboard only for development
    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ControlServerWeb.Telemetry
    end

    # Enablees Storybook ony for development
    scope "/" do
      storybook_assets()
    end

    scope "/", ControlServerWeb do
      pipe_through :browser
      live_storybook("/storybook", backend_module: ControlServerWeb.Storybook)
    end
  end
end
