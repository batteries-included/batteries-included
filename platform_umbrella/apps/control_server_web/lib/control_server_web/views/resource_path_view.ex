defmodule ControlServerWeb.ResourcePathView do
  use ControlServerWeb, :view
  alias ControlServerWeb.ResourcePathView

  def render("index.json", %{resource_paths: resource_paths}) do
    %{data: render_many(resource_paths, ResourcePathView, "resource_path.json")}
  end

  def render("show.json", %{resource_path: resource_path}) do
    %{data: render_one(resource_path, ResourcePathView, "resource_path.json")}
  end

  def render("resource_path.json", %{resource_path: resource_path}) do
    %{
      id: resource_path.id,
      path: resource_path.path,
      resource_value: resource_path.resource_value,
      hash: resource_path.hash,
      is_success: resource_path.is_success,
      apply_result: resource_path.apply_result
    }
  end
end
