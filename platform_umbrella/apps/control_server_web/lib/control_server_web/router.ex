defmodule ControlServerWeb.Router do
  use ControlServerWeb, :router

  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ControlServerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, ControlServerWeb.CSP.new()
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ControlServerWeb do
    pipe_through :browser

    live "/", Live.Home, :index

    live "/system_projects/", Live.SystemProjectIndex, :index
    live "/system_projects/new", Live.SystemProjectNew, :index
    live "/system_projects/:id/edit", Live.SystemProjectEdit, :edit
    live "/system_projects/:id/show", Live.SystemProjectShow, :show

    live "/postgres/clusters", Live.PostgresClusters, :index
    live "/postgres/clusters/new", Live.PostgresNew, :new
    live "/postgres/clusters/:id/edit", Live.PostgresEdit, :edit
    live "/postgres/clusters/:id/show", Live.PostgresShow, :show

    live "/redis/clusters", Live.Redis, :index
    live "/redis/clusters/new", Live.RedisNew, :new
    live "/redis/clusters/:id/edit", Live.RedisEdit, :edit
    live "/redis/clusters/:id/show", Live.RedisShow, :show

    live "/ceph", Live.CephIndex, :index
    live "/ceph/clusters/new", Live.CephClusterNew, :new
    live "/ceph/clusters/:id/edit", Live.CephClusterEdit, :edit
    live "/ceph/clusters/:id/show", Live.CephClusterShow, :show
    live "/ceph/filesystems/new", Live.CephFilesystemNew, :new
    live "/ceph/filesystems/:id/edit", Live.CephFilesystemEdit, :edit
    live "/ceph/filesystems/:id/show", Live.CephFilesystemShow, :show

    live "/knative/services", Live.KnativeServicesIndex, :index
    live "/knative/services/new", Live.KnativeNew, :new
    live "/knative/services/:id/edit", Live.KnativeEdit, :edit
    live "/knative/services/:id/show", Live.KnativeShow, :show

    live "/notebooks", Live.JupyterLabNotebook.Index, :index
    live "/notebooks/:id/show", Live.JupyterLabNotebook.Show, :index

    live "/ip_address_pools", Live.IPAddressPool.Index, :index

    live "/kiali", Live.Iframe, :kiali
    live "/gitea", Live.Iframe, :gitea

    live "/kube/deployments", Live.ResourceList, :deployment
    live "/kube/stateful_sets", Live.ResourceList, :stateful_set
    live "/kube/nodes", Live.ResourceList, :node
    live "/kube/pods", Live.ResourceList, :pod
    live "/kube/services", Live.ResourceList, :service

    live "/snapshot_apply", Live.SnapshotApplyIndex, :index
    live "/snapshot_apply/:id/show", Live.KubeSnapshotShow, :index

    live "/kube/raw/:resource_type/:namespace/:name", Live.RawResource, :index
    live "/kube/:resource_type/:namespace/:name", Live.ResourceInfo, :index

    live "/batteries/data", GroupBatteriesLive, :data
    live "/batteries/devtools", GroupBatteriesLive, :devtools
    live "/batteries/ml", GroupBatteriesLive, :ml
    live "/batteries/monitoring", GroupBatteriesLive, :monitoring
    live "/batteries/net_sec", GroupBatteriesLive, :net_sec
    live "/batteries/magic", GroupBatteriesLive, :magic
    live "/batteries", SystemBatteryLive.Index, :index
    live "/batteries/:id", SystemBatteryLive.Show, :show

    live "/timeline", TimelineLive, :index
  end

  scope "/api", ControlServerWeb do
    pipe_through :api
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Enum.member?([:dev, :test], Mix.env()) do
    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: ControlServerWeb.Telemetry
    end

    scope "/api" do
      pipe_through :api

      get "/system_state", ControlServerWeb.SystemStateController, :index
    end
  end
end
