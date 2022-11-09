defmodule KubeExt.ResourceGenerator do
  alias K8s.Resource

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :resource_generator, accumulate: true, persist: false)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro resource(name, battery \\ quote(do: _), state \\ quote(do: _), do: resource_block) do
    quote do
      @resource_generator unquote(name)
      def unquote(name)(unquote(battery), unquote(state)), do: unquote(resource_block)
    end
  end

  def perform_materialize(module, generators, battery, state) do
    generators
    |> do_apply(module, battery, state)
    |> flatten_to_tuple()
    |> filter_exists()
    |> dedupe_path()
    |> to_map()
  end

  defp filter_exists(resources) do
    Enum.reject(resources, fn {_path, r} -> r == nil || Enum.empty?(r) end)
  end

  defp do_apply(generators, module, battery, state) do
    Enum.map(generators, fn method ->
      # Do the actual work of creating the resource
      apply(module, method, [battery, state])
    end)
  end

  defp flatten_to_tuple(resources) do
    Enum.flat_map(resources, fn
      # We might or might not get a list.
      # This will make it so everything is uniform
      resource_list when is_list(resource_list) ->
        Enum.map(resource_list, fn r -> {to_path(r), r} end)

      resource ->
        [{to_path(resource), resource}]
    end)
  end

  defp dedupe_path(resources) do
    resources
    |> Enum.group_by(fn {path, _} -> path end, fn {_path, res} -> res end)
    |> Enum.flat_map(fn
      # After grouping by path it's possible that there are
      # two resources with the same path (different namespaces)
      # This will flatten this adding the index to the path if needed.
      {path, rl} when length(rl) > 1 ->
        rl
        |> Enum.with_index()
        |> Enum.map(fn {r, idx} -> {Path.join(path, Integer.to_string(idx)), r} end)

      {path, rl} ->
        # There's one or none in the list
        Enum.map(rl, fn r -> {path, r} end)
    end)
  end

  defp to_map(resources) do
    # Dump this back into a map
    Map.new(resources)
  end

  defp to_path(resource) do
    Path.join(["/", type_path(resource), name_path(resource)])
  end

  defp type_path(resource) do
    case KubeExt.ApiVersionKind.resource_type(resource) do
      nil -> fallback_type_path(resource)
      atom_type -> Atom.to_string(atom_type)
    end
  end

  defp fallback_type_path(resource) do
    resource
    |> Resource.api_version()
    |> Path.join(Resource.kind(resource))
    |> sanitize_path()
  end

  defp name_path(resource) do
    resource |> Resource.name() |> sanitize_path()
  end

  defp sanitize_path(path_part) do
    path_part |> String.downcase() |> String.split(~r/[^\w\d]/, trim: true) |> Enum.join("_")
  end

  defmacro __before_compile__(%{module: module} = _env) do
    method =
      module
      |> Module.get_attribute(:resource_generator, [])
      |> then(fn generators ->
        quote do
          def materialize(battery, state) do
            KubeExt.ResourceGenerator.perform_materialize(
              __MODULE__,
              unquote(generators),
              battery,
              state
            )
          end
        end
      end)

    quote do
      unquote(method)
    end
  end
end
