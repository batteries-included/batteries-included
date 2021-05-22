defmodule HomeBaseWeb.Router do
  use HomeBaseWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HomeBaseWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HomeBaseWeb do
    pipe_through :browser

    live "/", PageLive, :index

    live "/stripe_subscriptions", StripeSubscriptionLive.Index, :index
    live "/stripe_subscriptions/new", StripeSubscriptionLive.Index, :new
    live "/stripe_subscriptions/:id/edit", StripeSubscriptionLive.Index, :edit

    live "/stripe_subscriptions/:id", StripeSubscriptionLive.Show, :show
    live "/stripe_subscriptions/:id/show/edit", StripeSubscriptionLive.Show, :edit

    live "/usage_reports", UsageReportLive.Index, :index
    live "/usage_reports/new", UsageReportLive.Index, :new
    live "/usage_reports/:id/edit", UsageReportLive.Index, :edit

    live "/usage_reports/:id", UsageReportLive.Show, :show
    live "/usage_reports/:id/show/edit", UsageReportLive.Show, :edit
  end

  # Other scopes may use custom stacks.
  scope "/api", HomeBaseWeb do
    pipe_through :api
    resources "/usage_reports", UsageReportController, except: [:new, :edit]
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
      live_dashboard "/dashboard", metrics: HomeBaseWeb.Telemetry
    end
  end
end
