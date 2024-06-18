defmodule HomeBaseWeb.Router do
  use HomeBaseWeb, :router

  import HomeBaseWeb.UserAuth

  @redirect_authenticated_user {HomeBaseWeb.UserAuth, :redirect_authenticated_user}
  @ensure_authenticated_user {HomeBaseWeb.UserAuth, :ensure_authenticated}
  @mount_current_user {HomeBaseWeb.UserAuth, :mount_current_user}

  @root_layout {HomeBaseWeb.Layouts, :root}
  @auth_layout {HomeBaseWeb.Layouts, :auth}
  @app_layout {HomeBaseWeb.Layouts, :app}

  pipeline :auth_layout, do: plug(:put_layout, html: @auth_layout)
  pipeline :app_layout, do: plug(:put_layout, html: @app_layout)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_user
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, html: @root_layout
    plug :put_layout, false
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Enum.member?([:dev, :test], Mix.env()) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
      live_dashboard "/dashboard", metrics: HomeBaseWeb.Telemetry
    end
  end

  scope "/", HomeBaseWeb do
    pipe_through :browser

    delete "/logout", UserSessionController, :delete
  end

  scope "/", HomeBaseWeb do
    pipe_through [:browser, :auth_layout]

    live_session :confirm, layout: @auth_layout, on_mount: [@mount_current_user] do
      live "/confirm/:token", ConfirmLive
    end
  end

  scope "/", HomeBaseWeb do
    pipe_through [:browser, :auth_layout, :redirect_authenticated_user]

    post "/login", UserSessionController, :create

    live_session :auth, layout: @auth_layout, on_mount: [@redirect_authenticated_user] do
      live "/signup", SignupLive
      live "/login", LoginLive
      live "/reset", ForgotPasswordLive
      live "/reset/:token", ResetPasswordLive
    end
  end

  scope "/", HomeBaseWeb do
    pipe_through [:browser, :app_layout, :require_authenticated_user]

    live_session :app, layout: @app_layout, on_mount: [@ensure_authenticated_user] do
      live "/", DashboardLive

      live "/installations/", InstallationLive
      live "/installations/:id", InstallationShowLive

      live "/teams/new", TeamsNewLive

      live "/settings", SettingsLive
      live "/settings/:token", SettingsLive
    end

    get "/teams/:id", TeamsController, :switch
  end

  scope "/api/v1/", HomeBaseWeb do
    pipe_through :api

    scope "/installations/:installation_id" do
      resources "/usage_reports", StoredUsageReportController, only: [:create]
      resources "/host_reports", StoredHostReportController, only: [:create]
      get "/status", InstallationStatusContoller, :show
    end
  end
end
