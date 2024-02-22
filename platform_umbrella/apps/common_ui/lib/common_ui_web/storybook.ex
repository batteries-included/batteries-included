defmodule CommonUIWeb.Storybook do
  @moduledoc false
  use PhoenixStorybook,
    otp_app: :common_ui,
    title: "Batteries Included",
    sandbox_class: "common-ui",
    css_path: "/assets/storybook.css",
    js_path: "/assets/storybook.js",
    content_path: Path.expand("../../storybook", __DIR__)
end
