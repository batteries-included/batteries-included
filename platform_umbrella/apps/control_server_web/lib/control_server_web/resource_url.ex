defmodule ControlServerWeb.ResourceURL do
  use ControlServerWeb, :verified_routes

  alias CommonCore.ApiVersionKind
  alias K8s.Resource

  def resource_show_url(%{} = resource, params \\ %{}) do
    resource_type = ApiVersionKind.resource_type(resource)
    namespace = Resource.namespace(resource)
    name = Resource.name(resource)

    merge_params(~p"/kube/#{resource_type}/#{namespace}/#{name}", params)
  end

  defp merge_params(base_url, %{} = params) when map_size(params) > 0 do
    "#{base_url}?#{URI.encode_query(params)}"
  end

  defp merge_params(base_url, %{} = _params) do
    "#{base_url}"
  end
end
