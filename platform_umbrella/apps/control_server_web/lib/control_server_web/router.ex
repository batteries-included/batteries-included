defmodule ControlServerWeb.Router do
  use ControlServerWeb, :router

  import ControlServerWeb.UserAuth

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ControlServerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, ControlServerWeb.CSP.new()
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :full_layout do
    plug :put_layout, {ControlServerWeb.LayoutView, "full.html"}
  end

  scope "/", ControlServerWeb do
    pipe_through :browser

    live "/", Live.Home, :index

    live "/data", Live.DataHome, :index
    live "/postgres_clusters", Live.PostgresClusters, :index
    live "/postgres_clusters/new", Live.PostgresNew, :new
    live "/postgres_clusters/:id/edit", Live.PostgresEdit, :edit
    live "/postgres_clusters/:id/show", Live.PostgresShow, :show

    live "/failover_clusters", Live.Redis, :index
    live "/failover_clusters/new", Live.RedisNew, :new
    live "/failover_clusters/:id/edit", Live.RedisEdit, :edit
    live "/failover_clusters/:id/show", Live.RedisShow, :show

    live "/ceph", Live.CephIndex, :index
    live "/ceph/cluster/new", Live.CephClusterNew, :new
    live "/ceph/cluster/:id/edit", Live.CephClusterEdit, :edit
    live "/ceph/cluster/:id/show", Live.CephClusterShow, :show
    live "/ceph/filesystem/new", Live.CephFilesystemNew, :new
    live "/ceph/filesystem/:id/edit", Live.CephFilesystemEdit, :edit
    live "/ceph/filesystem/:id/show", Live.CephFilesystemShow, :show

    live "/knative_services", Live.KnativeServicesIndex, :index
    live "/knative_services/new", Live.KnativeNew, :new
    live "/knative_services/:id/edit", Live.KnativeEdit, :edit
    live "/knative_services/:id/show", Live.KnativeShow, :show

    live "/network/status", Live.NetworkStatus, :index

    live "/notebooks", Live.JupyterLabNotebook.Index, :index
    live "/notebooks/:id", Live.JupyterLabNotebook.Show, :index

    live "/kiali", Live.Iframe, :kiali
    live "/grafana", Live.Iframe, :grafana
    live "/alert_manager", Live.Iframe, :alert_manager
    live "/prometheus", Live.Iframe, :prometheus
    live "/gitea", Live.Iframe, :gitea

    live "/monitoring/settings", Live.ServiceSettings, :monitoring
    live "/data/settings", Live.ServiceSettings, :data
    live "/devtools/settings", Live.ServiceSettings, :devtools
    live "/network/settings", Live.ServiceSettings, :network
    live "/security/settings", Live.ServiceSettings, :security
    live "/ml/settings", Live.ServiceSettings, :ml

    live "/deployments", Live.ResourceList, :deployments
    live "/stateful_sets", Live.ResourceList, :stateful_sets
    live "/nodes", Live.ResourceList, :nodes
    live "/pods", Live.ResourceList, :pods
    live "/services", Live.ResourceList, :services
    live "/kube_snapshots", Live.KubeSnapshotList, :index
    live "/kube_snapshots/:id", Live.KubeSnapshotShow, :index
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

  ## Authentication routes
  scope "/", ControlServerWeb do
    pipe_through [:full_layout, :browser]

    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ControlServerWeb do
    pipe_through [:full_layout, :browser, :redirect_if_user_is_authenticated]

    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", ControlServerWeb do
    pipe_through [:browser]

    live "/users", Live.UserIndex, :index
    live "/users/new", Live.UserNew, :index

    delete "/users/log_out", UserSessionController, :delete

    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :edit
    post "/users/confirm/:token", UserConfirmationController, :update
  end

  scope "/", ControlServerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/users/:id/show", Live.UserShow, :index
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end
end
