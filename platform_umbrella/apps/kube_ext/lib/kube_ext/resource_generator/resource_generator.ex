defmodule KubeExt.ResourceGenerator do
  alias K8s.Resource
  alias KubeExt.Builder, as: B
  alias KubeExt.Hashing
  alias KubeExt.CopyLabels

  defmacro __using__(opts \\ []) do
    app_name = Keyword.get(opts, :app_name, nil)

    [main_macro_content(opts), app_name_macro_contents(app_name)]
  end

  defp main_macro_content(opts) do
    quote do
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :resource_generator, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :resource_generator_opts, [])

      @resource_generator_opts unquote(opts)

      @before_compile unquote(__MODULE__)
    end
  end

  defp app_name_macro_contents(nil), do: nil

  defp app_name_macro_contents(app_name) do
    string_name = to_string(app_name)

    quote do
      @app_name unquote(string_name)

      def app_name, do: unquote(string_name)
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

  def perform_materialize(module, generators, opts, battery, state) do
    resources = generate_resources(module, generators, battery, state)
    multi_resources = generate_multi_resources(module, generators, battery, state)

    (resources ++ multi_resources)
    |> filter_exists()
    |> dedupe_path()
    |> enrich(opts, battery, state)
    |> to_map()
  end

  defp generate_resources(module, generators, battery, state) do
    generators
    |> pluck_generator_type(:single)
    |> do_apply(module, battery, state)
    |> flatten_to_tuple()
  end

  defp generate_multi_resources(module, generators, battery, state) do
    generators
    |> pluck_generator_type(:multi)
    |> do_apply(module, battery, state)
    |> flatten_multis_to_tuple()
  end

  defp enrich(resource_path_list, opts, battery, _state) do
    resource_path_list
    |> maybe_add_app_name(opts)
    |> Enum.map(fn {path, resource} ->
      {path,
       resource
       |> B.managed_labels()
       |> add_owner(battery)
       |> CopyLabels.copy_labels_downward()
       |> Hashing.decorate()}
    end)
  end

  defp maybe_add_app_name(resources, opts) do
    name = Keyword.get(opts, :app_name, nil)

    case name do
      nil ->
        resources

      "" ->
        resources

      app_name ->
        Enum.map(resources, fn {path, resource} ->
          {path, B.app_labels(resource, to_string(app_name))}
        end)
    end
  end

  defp add_owner(resource, %{id: nil}), do: resource
  defp add_owner(resource, %{id: id}), do: B.owner_label(resource, id)
  defp add_owner(resource, _), do: resource

  defp pluck_generator_type(generators, keep_type) do
    generators
    |> Enum.filter(fn {type, _} -> keep_type == type end)
    |> Enum.map(fn {_type, gen} -> gen end)
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
    case CommonCore.ApiVersionKind.resource_type(resource) do
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
    opts = Module.get_attribute(module, :resource_generator_opts, [])

    quote do
      def materialize(battery, state) do
        KubeExt.ResourceGenerator.perform_materialize(
          __MODULE__,
          unquote(generators),
          unquote(opts),
          battery,
          state
        )
      end
    end
  end
end
