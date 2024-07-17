defmodule ControlServerWeb.ResourceHTMLHelper do
  @moduledoc false
  use ControlServerWeb, :verified_routes

  import CommonCore.Resources.FieldAccessors

  alias CommonCore.ApiVersionKind

  def resource_path(%{} = resource, action \\ :show, params \\ %{}) do
    resource_type = ApiVersionKind.resource_type(resource)
    namespace = namespace(resource)
    name = name(resource)

    path = "/kube/#{resource_type}/#{namespace}/#{name}/#{Atom.to_string(action)}"

    if Enum.empty?(params) do
      path
    else
      "#{path}?#{URI.encode_query(params)}"
    end
  end

  def raw_resource_path(%{} = resource) do
    resource_type = ApiVersionKind.resource_type(resource)
    namespace = namespace(resource)
    name = name(resource)

    "/kube/raw/#{resource_type}/#{namespace}/#{name}"
  end

  def to_html_id(%{"containerID" => id}) do
    String.trim_leading(id, "containerd://")
  end

  def to_html_id(resource) do
    [kind(resource), namespace(resource), name(resource)] |> Enum.filter(& &1) |> Enum.join("_") |> String.downcase()
  end
end
