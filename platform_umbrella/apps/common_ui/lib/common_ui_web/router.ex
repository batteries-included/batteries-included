defmodule CommonUIWeb.Router do
  use Phoenix.Router, helpers: false

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/" do
    if Enum.member?([:dev, :test], Mix.env()) do
      import PhoenixStorybook.Router

      storybook_assets()
    end
  end

  scope "/", CommonUIWeb do
    pipe_through :browser

    if Enum.member?([:dev, :test], Mix.env()) do
      import PhoenixStorybook.Router

      live_storybook("/", backend_module: CommonUIWeb.Storybook)
    end
  end
end
