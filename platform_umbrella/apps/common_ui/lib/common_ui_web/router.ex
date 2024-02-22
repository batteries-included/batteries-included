defmodule CommonUIWeb.Router do
  use Phoenix.Router, helpers: false

  import PhoenixStorybook.Router

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    storybook_assets()
  end

  scope "/", CommonUIWeb do
    pipe_through :browser

    live_storybook("/", backend_module: CommonUIWeb.Storybook)
  end
end
