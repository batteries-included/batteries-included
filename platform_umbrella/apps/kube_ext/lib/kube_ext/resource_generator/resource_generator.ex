defmodule KubeExt.ResourceGenerator do
  alias K8s.Resource

  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :resource_generator, accumulate: true, persist: false)

      Module.register_attribute(__MODULE__, :multi_resource_generator,
        accumulate: true,
        persist: false
      )

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro resource(name, battery \\ quote(do: _battery), state \\ quote(do: _state),
             do: resource_block
           ) do
    quote do
      @resource_generator {:single, unquote(name)}
      def unquote(name)(unquote(battery), unquote(state)), do: unquote(resource_block)
    end
  end

  defmacro multi_resource(name, battery \\ quote(do: _battery), state \\ quote(do: _state),
             do: resource_block
           ) do
    quote do
      @resource_generator {:multi, unquote(name)}
      def unquote(name)(unquote(battery), unquote(state)), do: unquote(resource_block)
    end
  end

  def perform_materialize(module, generators, battery, state) do
    gen_resources =
      generators
      |> pluck_generator_type(:single)
      |> do_apply(module, battery, state)
      |> flatten_to_tuple()

    multi_resources =
      generators
      |> pluck_generator_type(:multi)
      |> do_apply(module, battery, state)
      |> flatten_multis_to_tuple()

    (gen_resources ++ multi_resources)
    |> filter_exists()
    |> dedupe_path()
    |> copy_labels()
    |> to_map()
  end

  defp pluck_generator_type(generators, keep_type) do
    generators
    |> Enum.filter(fn {type, _} -> keep_type == type end)
    |> Enum.map(fn {_type, gen} -> gen end)
  end

  defp copy_labels(resources) do
    Enum.map(resources, fn {path, resource} ->
      {path, KubeExt.CopyLabels.copy_labels_downward(resource)}
    end)
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
        resource_list
        # FilterResource can send nils
        |> Enum.reject(fn r -> r == nil end)
        # Prepare to make the map
        |> Enum.map(fn r -> {to_path(r), r} end)

      nil ->
        []

      resource ->
        [{to_path(resource), resource}]
    end)
  end

  defp flatten_multis_to_tuple(list_maps) do
    Enum.flat_map(list_maps, fn
      # If the whole map is nil then just sidestep the whole thing.
      nil ->
        []

      res_map when is_map(res_map) ->
        res_map
        # nils are out
        |> Enum.reject(fn {_, r} -> r == nil end)
        # Map everything to a path, resource tuple
        |> Enum.map(fn {base_path, res} -> {Path.join(base_path, to_path(res)), res} end)

      res_list when is_list(res_list) ->
        res_list
        |> Enum.reject(fn
          # Since Filters might send nils through here
          # reject anything that looks like nil
          {_, r} -> r == nil
          r -> r == nil
        end)
        |> Enum.map(fn
          {base_path, res} -> {Path.join(base_path, to_path(res)), res}
          res -> {to_path(res), res}
        end)
    end)
  end

  defp dedupe_path(resources) do
    resources
    |> Enum.group_by(fn {path, _} -> path end, fn {_path, res} -> res end)
    |> Enum.flat_map(&grouped_resources_to_path_map/1)
  end

  defp to_map(resources) do
    # Dump this back into a map
    Map.new(resources)
  end

  defp grouped_resources_to_path_map({path, resource_list}) when length(resource_list) > 1 do
    # After grouping by path it's possible that there are
    # two resources with the same path (different namespaces)
    # This will flatten this adding the index to the path if needed.
    resource_list
    |> Enum.with_index()
    |> Enum.map(fn {r, idx} -> {Path.join(path, Integer.to_string(idx)), r} end)
  end

  defp grouped_resources_to_path_map({path, resource_list}) do
    # There's one or none in the list so it can have the path all to itself
    resource_list |> Enum.map(fn r -> {path, r} end) |> Enum.take(1)
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
    generators = Module.get_attribute(module, :resource_generator, [])

    method =
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

    quote do
      unquote(method)
    end
  end
end
