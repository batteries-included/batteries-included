defmodule ControlServerWeb.ResourceURL do
  alias ControlServerWeb.Router.Helpers, as: Routes
  alias ControlServerWeb.Endpoint
  alias KubeExt.ApiVersionKind
  alias K8s.Resource

  def resource_show_url(%{} = resource) do
    Routes.resource_info_path(
      Endpoint,
      :index,
      ApiVersionKind.resource_type(resource),
      Resource.namespace(resource),
      Resource.name(resource)
    )
  end
end
