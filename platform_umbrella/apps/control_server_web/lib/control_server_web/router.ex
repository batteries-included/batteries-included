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

    live "/services/monitoring/settings", Live.MonitoringServiceSettings, :index
    live "/services/monitoring/prometheus", Live.Prometheus, :index
    live "/services/monitoring/alert_manager", Live.Alertmanager, :index
    live "/services/monitoring/grafana", Live.Grafana, :index

    live "/services/data", Live.DataHome, :index
    live "/services/data/settings", Live.DataServiceSettings, :index
    live "/services/data/postgres_clusters", Live.PostgresClusters, :index
    live "/services/data/postgres_clusters/new", Live.PostgresNew, :new
    live "/services/data/postgres_clusters/:id/edit", Live.PostgresEdit, :edit

    live "/services/data/failover_clusters", Live.Redis, :index
    live "/services/data/failover_clusters/new", Live.RedisNew, :new
    live "/services/data/failover_clusters/:id/edit", Live.RedisEdit, :edit

    live "/services/devtools/settings", Live.DevtoolsServiceSettings, :index
    live "/services/devtools/gitea", Live.Gitea, :index
    live "/services/devtools/knative_services", Live.KnativeServicesIndex, :index
    live "/services/devtools/knative_services/new", Live.KnativeNew, :new
    live "/services/devtools/knative_services/:id/edit", Live.KnativeEdit, :edit

    live "/services/network/settings", Live.NetworkServiceSettings, :index
    live "/services/network/status", Live.NetworkStatus, :index
    live "/services/network/kiali", Live.Kiali, :index

    live "/services/security/settings", Live.SecurityServiceSettings, :index

    live "/services/ml/settings", Live.MLServiceSettings, :index
    live "/services/ml/notebooks", Live.JupyterLabNotebook.Index, :index
    live "/services/ml/notebooks/:id", Live.JupyterLabNotebook.Show, :index

    live "/internal/deployments", Live.Deployments, :index
    live "/internal/nodes", Live.Nodes, :index
    live "/internal/pods", Live.Pods, :index
    live "/internal/stateful_sets", Live.StatefulSets, :index
    live "/internal/workers", Live.WorkerList, :index
  end

  scope "/api", ControlServerWeb do
    pipe_through :api
    resources "/base_services", BaseServiceController, except: [:new, :edit]
    resources "/usage_reports", UsageReportController, except: [:new, :edit]
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
