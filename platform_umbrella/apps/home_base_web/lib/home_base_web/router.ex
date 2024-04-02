defmodule HomeBaseWeb.Router do
  use HomeBaseWeb, :router

  import HomeBaseWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HomeBaseWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## Main application routes
  # Ensure the user is authenticated before accessing
  # any page other than designated routes for authentication
  scope "/", HomeBaseWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :main_app_auth_required,
      on_mount: [{HomeBaseWeb.UserAuth, :ensure_authenticated}] do
      ## Application Routes
      live "/", Live.Home, :index

      live "/installations/", Live.Installations, :index
      live "/installations/new", Live.InstallationNew, :index
      live "/installations/:id/show", Live.InstallatitonShow, :show
    end
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

      live_dashboard "/dashboard", metrics: HomeBaseWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", HomeBaseWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :auth_related_unauth_required,
      on_mount: [{HomeBaseWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      ## Authentication routes
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", HomeBaseWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :auth_related_auth_required,
      on_mount: [{HomeBaseWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", HomeBaseWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :auth_related_auth_available,
      on_mount: [{HomeBaseWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
