defmodule ControlServerWeb.ResourceURL do
  @moduledoc false
  use ControlServerWeb, :verified_routes

  alias CommonCore.ApiVersionKind
  alias K8s.Resource

  def resource_show_path(%{} = resource, params \\ %{}) do
    resource_type = ApiVersionKind.resource_type(resource)
    namespace = Resource.namespace(resource)
    name = Resource.name(resource)
    show_path(resource_type, namespace, name, params)
  end

  def show_path(resource_type, namespace, name, params \\ %{}) do
    # Phoenix "verified routes" throws a warning if we try to dynamically insert the resource_type
    case resource_type do
      :pod -> ~p"/kube/pod/#{namespace}/#{name}?#{params}"
      :deployment -> ~p"/kube/deployment/#{namespace}/#{name}?#{params}"
      :stateful_set -> ~p"/kube/stateful_set/#{namespace}/#{name}?#{params}"
      :service -> ~p"/kube/service/#{namespace}/#{name}?#{params}"
    end
  end
end
