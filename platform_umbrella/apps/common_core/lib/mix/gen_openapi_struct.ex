defmodule Mix.Tasks.Gen.Openapi.Struct do
  @shortdoc "Given a json schema for open api generate a module for the given stuct types"

  use Mix.Task
  use TypedStruct

  @dont_specialize_spec_types ["ResourceRepresentation"]

  def run(args) do
    [path, schema, module_name] = args

    {:ok, contents} = File.read(path)

    {:ok, open_api} = Jason.decode(contents)

    module = module(open_api, schema, module_name)

    module_file_name = Macro.underscore(module_name)

    schema_file =
      Path.join(File.cwd!(), "apps/common_core/lib/common_core/open_api/#{module_file_name}.ex")

    File.write!(schema_file, contents(module))
  end

  typedstruct module: State do
    field :modules, map(), default: %{}
    field :deps, map(), default: %{}
  end

  def contents(module) do
    module
    |> Macro.to_string()
    |> String.split("\n")
    |> Enum.map_join("\n", fn line ->
      Regex.replace(~r/^(\s+)field\((.*)\)$/, line, "\\1 field \\2")
    end)
  end

  def module(open_api, root_schema, module_name) do
    state = add(%State{}, open_api, root_schema)
    module_name = String.to_atom("Elixir.CommonCore.OpenApi.#{module_name}")
    {:ok, modules_sorted} = sorted_modules(state)

    quote do
      defmodule unquote(module_name) do
        use TypedStruct
        import CommonCore.OpenApi.AtomTools

        unquote_splicing(modules_sorted)
      end
    end
  end

  defp sorted_modules(state) do
    do_sorted_modules([], state)
  end

  defp do_sorted_modules(result, %State{modules: modules}) when map_size(modules) == 0 do
    {:ok, Enum.reverse(result)}
  end

  defp do_sorted_modules(result, %State{deps: deps} = state) do
    possible =
      deps
      |> Enum.filter(fn {_schema_name, deps} -> Enum.empty?(deps) end)
      |> List.first()

    case possible do
      nil ->
        dbg(state.deps)
        {:error, :cant_find_no_deps}

      {schema_name, _} ->
        {new_result, new_state} = add_sorted_module(result, state, schema_name)
        do_sorted_modules(new_result, new_state)
    end
  end

  defp add_sorted_module(result, state, schema_name) do
    module = Map.fetch!(state.modules, schema_name)

    new_deps =
      state.deps
      |> Enum.map(fn {k, deps} -> {k, Enum.reject(deps, &(&1 == schema_name))} end)
      |> Enum.reject(fn {k, _v} -> k == schema_name end)
      |> Map.new()

    {[module | result],
     %State{state | modules: Map.delete(state.modules, schema_name), deps: new_deps}}
  end

  defp add(state, open_api, schema_name) do
    schema = get_in(open_api, ["components", "schemas", schema_name])

    cond do
      Map.has_key?(state.modules, schema_name) -> state
      schema != nil -> do_add(state, open_api, schema_name, schema)
      true -> state
    end
  end

  defp do_add(state, open_api, schema_name, schema) do
    {seen, schema} = definition(schema, schema_name)

    with_this = %State{
      state
      | modules: Map.put(state.modules, schema_name, schema),
        deps: Map.put(state.deps, schema_name, seen)
    }

    Enum.reduce(seen, with_this, fn seen_schema_name, latest_state ->
      add(latest_state, open_api, seen_schema_name)
    end)
  end

  defp definition(%{} = schema, schema_name) do
    properties = schema |> Map.get("properties", []) |> Enum.sort_by(fn {name, _} -> name end)

    if Enum.empty?(properties) do
      {[], nil}
    else
      typed_struct = typed_struct(schema_name, properties)

      seen = seen_schema_names(schema_name, properties)

      decode = decode_fn(schema_name, properties)

      res =
        quote do
          defmodule unquote(String.to_atom("Elixir.#{schema_name}")) do
            @derive Jason.Encoder

            unquote(typed_struct)

            # The decode block
            unquote(decode)
          end
        end

      {seen, res}
    end
  end

  defp typed_struct(schema_name, properties) do
    inner = Enum.map(properties, fn prop -> field_def(schema_name, prop) end)

    quote do
      typedstruct do
        # Add each of the fields here
        # Each of the `field_defs` will be a quoted call to the `field` macro
        (unquote_splicing(inner))
      end
    end
  end

  def decode_fn(schema_name, properties) do
    specialized_properties =
      properties
      |> Enum.map(fn property -> decode_property_fn(schema_name, property) end)
      |> Enum.reject(&is_nil/1)

    quote do
      def decode(args) do
        fields =
          args
          |> Enum.map(&decode_property/1)
          |> Enum.reject(&is_nil/1)

        struct(unquote(String.to_atom("Elixir.#{schema_name}")), fields)
      end

      def decode_list(items), do: Enum.map(items, &decode/1)

      ## The specialized decode function
      unquote_splicing(specialized_properties)

      defp decode_property({key, value}) do
        case maybe_exiting_atom(key) do
          {:ok, atom_key} -> {atom_key, value}
          _ -> nil
        end
      end
    end
  end

  defp decode_property_fn("ResourceRepresentation", _), do: nil

  defp decode_property_fn(_schema_name, {property_name, %{"$ref" => ref_name}}) do
    case ref_name_to_schema_name(ref_name) do
      nil ->
        nil

      inner_schema_name ->
        quote do
          defp decode_property({unquote(property_name), value}),
            do:
              {unquote(String.to_atom(property_name)),
               unquote(String.to_atom("Elixir.#{inner_schema_name}")).decode(value)}
        end
    end
  end

  defp decode_property_fn(_schema_name, {property_name, %{"items" => %{"$ref" => ref_name}}}) do
    case ref_name_to_schema_name(ref_name) do
      nil ->
        nil

      inner_schema_name ->
        quote do
          defp decode_property({unquote(property_name), items}),
            do:
              {unquote(String.to_atom(property_name)),
               unquote(String.to_atom("Elixir.#{inner_schema_name}")).decode_list(items)}
        end
    end
  end

  defp decode_property_fn(_schema_name, {_property_name, _property}), do: nil

  def seen_schema_names(schema_name, properties) do
    if Enum.member?(@dont_specialize_spec_types, schema_name) do
      []
    else
      properties
      |> Enum.map(fn {_property_name, info} ->
        ref_schema_name(info)
      end)
      |> Enum.filter(fn value -> value != nil && value != schema_name end)
      |> Enum.uniq()
    end
  end

  defp ref_schema_name(%{"$ref" => ref_name}), do: ref_name_to_schema_name(ref_name)

  defp ref_schema_name(%{"items" => %{"$ref" => ref_name}}),
    do: ref_name_to_schema_name(ref_name)

  defp ref_schema_name(%{"additionalProperties" => additional_properties}),
    do: ref_schema_name(additional_properties)

  defp ref_schema_name(_), do: nil

  defp ref_name_to_schema_name(ref_name) do
    case String.split(ref_name, "#/components/schemas/") do
      ["", "OAuthClientRepresentation"] -> nil
      ["", schema_name] -> schema_name
      _ -> nil
    end
  end

  defp field_def(schema_name, {field_name, field_info}) do
    type = type(schema_name, field_info)

    quote do
      field unquote(String.to_atom(field_name)), unquote(type), enforce: false
    end
  end

  defp type(_schema_name, %{"type" => "object"}) do
    quote do
      map()
    end
  end

  defp type(schema_name, %{"$ref" => _} = info) do
    case {Enum.member?(@dont_specialize_spec_types, schema_name), ref_schema_name(info)} do
      {_, nil} ->
        quote do
          map()
        end

      {true, _} ->
        quote do
          map()
        end

      {false, inner_schema_name} ->
        quote do
          unquote(String.to_atom("Elixir.#{inner_schema_name}")).t()
        end
    end
  end

  defp type(schema_name, %{"type" => "array"} = info) do
    case {Enum.member?(@dont_specialize_spec_types, schema_name), ref_schema_name(info)} do
      {_, nil} ->
        quote do
          list()
        end

      {true, _} ->
        quote do
          list()
        end

      {false, inner_schema_name} ->
        quote do
          list(unquote(String.to_atom("Elixir.#{inner_schema_name}")).t())
        end
    end
  end

  defp type(_schema_name, %{"type" => "string"}) do
    quote do
      String.t()
    end
  end

  defp type(_schema_name, %{"type" => "number", "format" => "float"}) do
    quote do
      float()
    end
  end

  defp type(_schema_name, %{"type" => "int32"}) do
    quote do
      integer()
    end
  end

  defp type(_schema_name, %{"type" => "integer"}) do
    quote do
      integer()
    end
  end

  defp type(_schema_name, %{"type" => "boolean"}) do
    quote do
      boolean()
    end
  end
end
