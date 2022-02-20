defmodule ControlServerWeb.BaseServiceView do
  use ControlServerWeb, :view
  alias ControlServerWeb.BaseServiceView

  def render("index.json", %{base_services: base_services}) do
    %{data: render_many(base_services, BaseServiceView, "base_service.json")}
  end

  def render("show.json", %{base_service: base_service}) do
    %{data: render_one(base_service, BaseServiceView, "base_service.json")}
  end

  def render("base_service.json", %{base_service: base_service}) do
    %{
      id: base_service.id,
      root_path: base_service.root_path,
      service_type: base_service.service_type,
      config: base_service.config
    }
  end
end
