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

    live "/services/monitoring/settings", ServicesLive.MonitoringServiceSettings, :index
    live "/services/monitoring/status", ServicesLive.MonitoringStatus, :index
    live "/services/monitoring/prometheus", ServicesLive.Prometheus, :index
    live "/services/monitoring/alertmanager", ServicesLive.Alertmanager, :index
    live "/services/monitoring/grafana", ServicesLive.Grafana, :index

    live "/services/database", ServicesLive.DatabaseHome, :index
    live "/services/database/settings", ServicesLive.DatabaseServiceSettings, :index
    live "/services/database/status", ServicesLive.DatabaseStatus, :index
    live "/services/database/clusters", ServicesLive.PostgresClusters, :index
    live "/services/database/clusters/new", ServicesLive.PostgresNew, :new
    live "/services/database/clusters/:id/edit", ServicesLive.PostgresEdit, :edit

    live "/services/devtools/settings", ServicesLive.DevtoolsServiceSettings, :index
    live "/services/devtools/status", ServicesLive.DevtoolsStatus, :index

    live "/services/network/settings", ServicesLive.NetworkServiceSettings, :index
    live "/services/network/status", ServicesLive.NetworkStatus, :index

    live "/services/security/settings", ServicesLive.SecurityServiceSettings, :index
    live "/services/security/status", ServicesLive.SecurityStatus, :index

    live "/services/ml", ServicesLive.MLHome, :index
    live "/services/ml/settings", ServicesLive.MLServiceSettings, :index
    live "/services/ml/status", ServicesLive.MLStatus, :index
    live "/services/ml/notebooks", ServicesLive.JupyterLabNotebook.Index, :index
    live "/services/ml/notebooks/:id", ServicesLive.JupyterLabNotebook.Show, :index
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
