defmodule ControlServerWeb.ResourceURL do
  use ControlServerWeb, :verified_routes

  alias CommonCore.ApiVersionKind
  alias K8s.Resource

  def resource_show_url(%{} = resource) do
    resource_type = ApiVersionKind.resource_type(resource)
    namespace = Resource.namespace(resource)
    name = Resource.name(resource)
    ~p"/kube/#{resource_type}/#{namespace}/#{name}"
  end
end
