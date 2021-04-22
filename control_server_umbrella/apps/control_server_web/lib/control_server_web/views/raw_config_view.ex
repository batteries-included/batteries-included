defmodule ControlServerWeb.RawConfigView do
  use ControlServerWeb, :view
  alias ControlServerWeb.RawConfigView

  def render("index.json", %{raw_configs: raw_configs}) do
    %{data: render_many(raw_configs, RawConfigView, "raw_config.json")}
  end

  def render("show.json", %{raw_config: raw_config}) do
    %{data: render_one(raw_config, RawConfigView, "raw_config.json")}
  end

  def render("raw_config.json", %{raw_config: raw_config}) do
    %{id: raw_config.id, path: raw_config.path, content: raw_config.content}
  end
end
