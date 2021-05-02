defmodule ControlServerWeb.Router do
  use ControlServerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ControlServerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ControlServerWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live "/services/monitoring", ServicesLive.Prometheus, :index
    live "/services/database", ServicesLive.Postgres, :index

    live "/services/database/clusters", ClusterLive.Index, :index
    live "/services/database/clusters/new", ClusterLive.Index, :new
    live "/services/database/clusters/:id/edit", ClusterLive.Index, :edit

    live "/services/database/clusters/:id", ClusterLive.Show, :show
    live "/services/database/clusters/:id/show/edit", ClusterLive.Show, :edit
  end

  scope "/api", ControlServerWeb do
    pipe_through :api
    resources "/base_services", BaseServiceController, except: [:new, :edit]
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ControlServerWeb.Telemetry
    end
  end
end
