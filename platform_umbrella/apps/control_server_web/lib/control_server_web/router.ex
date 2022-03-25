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
    live "/services/monitoring/status", Live.MonitoringStatus, :index
    live "/services/monitoring/tools", Live.MonitoringTools, :index
    live "/services/monitoring/prometheus", Live.Prometheus, :index
    live "/services/monitoring/alert_manager", Live.Alertmanager, :index
    live "/services/monitoring/grafana", Live.Grafana, :index

    live "/services/database", Live.DatabaseHome, :index
    live "/services/database/settings", Live.DatabaseServiceSettings, :index
    live "/services/database/status", Live.DatabaseStatus, :index
    live "/services/database/clusters", Live.PostgresClusters, :index
    live "/services/database/clusters/new", Live.PostgresNew, :new
    live "/services/database/clusters/:id/edit", Live.PostgresEdit, :edit

    live "/services/devtools/settings", Live.DevtoolsServiceSettings, :index
    live "/services/devtools/status", Live.DevtoolsStatus, :index
    live "/services/devtools/tools", Live.DevtoolsTools, :index
    live "/services/devtools/knative_services", Live.KnativeServicesIndex, :index
    live "/services/devtools/knative_services/new", Live.KnativeNew, :index
    live "/services/devtools/knative_services/:id/edit", Live.KnativeEdit, :index

    live "/services/network/settings", Live.NetworkServiceSettings, :index
    live "/services/network/status", Live.NetworkStatus, :index

    live "/services/security/settings", Live.SecurityServiceSettings, :index
    live "/services/security/status", Live.SecurityStatus, :index

    live "/services/ml", Live.MLHome, :index
    live "/services/ml/settings", Live.MLServiceSettings, :index
    live "/services/ml/status", Live.MLStatus, :index
    live "/services/ml/notebooks", Live.JupyterLabNotebook.Index, :index
    live "/services/ml/notebooks/:id", Live.JupyterLabNotebook.Show, :index

    live "/internal", Live.WorkerList, :index
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
