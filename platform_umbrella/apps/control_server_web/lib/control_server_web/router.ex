defmodule ControlServerWeb.Router do
  use ControlServerWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ControlServerWeb.LayoutView, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, ControlServerWeb.CSP.new()
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ControlServerWeb do
    pipe_through :browser

    live "/", Live.Home, :index

    live "/services/data", Live.DataHome, :index
    live "/services/data/postgres_clusters", Live.PostgresClusters, :index
    live "/services/data/postgres_clusters/new", Live.PostgresNew, :new
    live "/services/data/postgres_clusters/:id/edit", Live.PostgresEdit, :edit
    live "/services/data/postgres_clusters/:id/show", Live.PostgresShow, :show

    live "/services/data/failover_clusters", Live.Redis, :index
    live "/services/data/failover_clusters/new", Live.RedisNew, :new
    live "/services/data/failover_clusters/:id/edit", Live.RedisEdit, :edit
    live "/services/data/failover_clusters/:id/show", Live.RedisShow, :show

    live "/services/devtools/knative_services", Live.KnativeServicesIndex, :index
    live "/services/devtools/knative_services/new", Live.KnativeNew, :new
    live "/services/devtools/knative_services/:id/edit", Live.KnativeEdit, :edit
    live "/services/devtools/knative_services/:id/show", Live.KnativeShow, :show

    live "/services/network/status", Live.NetworkStatus, :index

    live "/services/ml/notebooks", Live.JupyterLabNotebook.Index, :index
    live "/services/ml/notebooks/:id", Live.JupyterLabNotebook.Show, :index

    live "/services/network/kiali", Live.Iframe, :kiali
    live "/services/monitoring/grafana", Live.Iframe, :grafana
    live "/services/monitoring/alert_manager", Live.Iframe, :alert_manager
    live "/services/monitoring/prometheus", Live.Iframe, :prometheus
    live "/services/devtools/gitea", Live.Iframe, :gitea

    live "/services/monitoring/settings", Live.ServiceSettings, :monitoring
    live "/services/data/settings", Live.ServiceSettings, :data
    live "/services/devtools/settings", Live.ServiceSettings, :devtools
    live "/services/network/settings", Live.ServiceSettings, :network
    live "/services/security/settings", Live.ServiceSettings, :security
    live "/services/ml/settings", Live.ServiceSettings, :ml

    live "/internal/deployments", Live.ResourceList, :deployments
    live "/internal/stateful_sets", Live.ResourceList, :stateful_sets
    live "/internal/nodes", Live.ResourceList, :nodes
    live "/internal/pods", Live.ResourceList, :pods
    live "/internal/services", Live.ResourceList, :services
    live "/internal/kube_snapshots", Live.KubeSnapshotList, :index
    live "/internal/kube_snapshots/:id", Live.KubeSnapshotShow, :index
  end

  scope "/api", ControlServerWeb do
    pipe_through :api
    resources "/base_services", BaseServiceController, except: [:new, :edit]
    resources "/usage_reports", UsageReportController, except: [:new, :edit]
    resources "/kube_snapshots", KubeSnapshotController, except: [:new, :edit]
    resources "/resource_paths", ResourcePathController, except: [:new, :edit]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() == :dev do
    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ControlServerWeb.Telemetry
    end
  end
end
