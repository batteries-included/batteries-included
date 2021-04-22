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

    ## RawConfig ##
    live "/raw_configs", RawConfigLive.Index, :index
    live "/raw_configs/new", RawConfigLive.Index, :new
    live "/raw_configs/:id/edit", RawConfigLive.Index, :edit

    live "/raw_configs/:id", RawConfigLive.Show, :show
    live "/raw_configs/:id/show/edit", RawConfigLive.Show, :edit

    live "/services/monitoring", ServicesLive.Monitoring, :index
  end

  scope "/api", ControlServerWeb do
    pipe_through :api

    resources "/raw_configs", RawConfigController, except: [:new, :edit]
    get "/configs/*path", ComputedConfigController, :show
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
