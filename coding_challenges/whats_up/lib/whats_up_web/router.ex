defmodule WhatsUpWeb.Router do
  use WhatsUpWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WhatsUpWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WhatsUpWeb do
    pipe_through :browser

    live "/", HomeLive.Home, :home

    live "/sites", SiteLive.Index, :index
    live "/sites/new", SiteLive.Index, :new
    live "/sites/:id/edit", SiteLive.Index, :edit

    live "/sites/:id", SiteLive.Show, :show
    live "/sites/:id/show/edit", SiteLive.Show, :edit
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:whats_up, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WhatsUpWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
