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

    live "/services/monitoring", ServicesLive.MonitoringHome, :index
    live "/services/monitoring/prometheus", ServicesLive.Prometheus, :index
    live "/services/monitoring/grafana", ServicesLive.Grafana, :index
    live "/services/security", ServicesLive.Security, :index

    live "/services/database", ServicesLive.PostgresHome, :index
    live "/services/database/clusters/new", ServicesLive.PostgresNew, :new

    live "/services/devtools", ServicesLive.DevtoolsHome, :index
    live "/services/devtools/install", ServicesLive.DevtoolsInstall, :index

    live "/services/network", ServicesLive.NetworkHome, :index
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
