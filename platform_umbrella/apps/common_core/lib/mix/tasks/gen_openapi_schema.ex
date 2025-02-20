defmodule Mix.Tasks.Gen.Openapi.Schema do
  @shortdoc "Given a json schema for open api generate a module for the given stuct types using Ecto.Schema"

  @moduledoc false
  use Mix.Task
  use TypedStruct

  @dont_specialize_spec_types [
    "ResourceRepresentation",
    "Currency",
    "Country",
    "Timezone",
    "CustomerChargeFiltersUsageObject",
    "CustomerChargeGroupsUsageObject",
    "CustomerChargeGroupedUsageObject"
  ]
  @field_regex ~r/^(\s*)(field|embeds_many|embeds_one)\((.*)\)$/

  def run(args) do
    [path, schema, module_name] = args

    {:ok, open_api} = decode(path)

    module = module(open_api, schema, module_name)

    module_file_name = Macro.underscore(module_name)

    schema_file =
      Path.join(File.cwd!(), "apps/common_core/lib/common_core/open_api/#{module_file_name}.ex")

    File.write!(schema_file, contents(module))
  end

  def decode(path) do
    if String.contains?(path, "yaml") do
      {:ok, contents} = YamlElixir.read_all_from_file(path)
      result = List.first(contents)
      {:ok, result}
    else
      {:ok, contents} = File.read(path)
      Jason.decode(contents)
    end
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
      Regex.replace(@field_regex, line, "\\1 \\2 \\3")
    end)
  end

  def module(open_api, root_schema, module_name) do
    state =
      if root_schema == "*" do
        open_api
        |> get_in(["components", "schemas"])
        |> Map.keys()
        |> Enum.reject(fn sn -> sn in @dont_specialize_spec_types end)
        |> Enum.sort()
        |> Enum.reduce(%State{}, fn schema_name, s ->
          add(s, open_api, schema_name)
        end)
      else
        add(%State{}, open_api, root_schema)
      end

    module_name = String.to_atom("Elixir.CommonCore.OpenAPI.#{module_name}")
    {:ok, modules_sorted} = sorted_modules(state)

    quote do
      defmodule unquote(module_name) do
        (unquote_splicing(modules_sorted))
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
        {:error, :cant_find_no_deps}

      {:single, schema_name} ->
        {new_result, new_state} = add_sorted_module(result, state, schema_name)
        do_sorted_modules(new_result, new_state)

      {schema_name, _} ->
        {new_result, new_state} = add_sorted_module(result, state, schema_name)
        do_sorted_modules(new_result, new_state)
    end
  end

  defp add_sorted_module(result, state, schema_name) do
    module = Map.fetch!(state.modules, schema_name)

    new_deps =
      state.deps
      |> Enum.map(fn {k, deps} ->
        kept = Enum.reject(deps, &(&1 == schema_name))

        {k, kept}
      end)
      |> Enum.reject(fn {k, _v} -> k == schema_name end)
      |> Map.new()

    {[module | result], %{state | modules: Map.delete(state.modules, schema_name), deps: new_deps}}
  end

  defp add(state, open_api, schema_name) do
    schema = get_in(open_api, ["components", "schemas", schema_name])

    cond do
      Map.has_key?(state.modules, schema_name) ->
        state

      schema != nil ->
        do_add(state, open_api, schema_name, schema)

      true ->
        state
    end
  end

  defp do_add(state, open_api, schema_name, schema) do
    {seen, schema} = definition(schema, schema_name, open_api)

    with_this = %{
      state
      | modules: Map.put(state.modules, schema_name, schema),
        deps: Map.put(state.deps, schema_name, seen)
    }

    Enum.reduce(seen, with_this, fn seen_schema_name, latest_state ->
      add(latest_state, open_api, seen_schema_name)
    end)
  end

  defp definition(%{"oneOf" => one_of} = _schema, schema_name, _open_api) do
    properties =
      one_of
      |> Enum.map(fn v -> Map.get(v, "properties", %{}) end)
      |> Enum.reduce(%{}, &Map.merge/2)
      |> Enum.sort_by(fn {name, _} -> name end)

    seen = seen_schema_names(schema_name, properties)
    res = typed_ecto_module(properties, schema_name)
    {seen, res}
  end

  defp definition(%{"allOf" => all_of} = schema, schema_name, open_api) do
    properties =
      all_of
      |> Enum.map(fn
        %{"properties" => properties} ->
          properties

        %{"$ref" => ref_name} ->
          get_in(open_api, ["components", "schemas", ref_name_to_schema_name(ref_name), "properties"]) || nil
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.reduce(%{}, &Map.merge/2)
      |> Map.merge(Map.get(schema, "properties", %{}))

    seen = seen_schema_names(schema_name, properties)
    res = typed_ecto_module(properties, schema_name)
    {seen, res}
  end

  defp definition(%{} = schema, schema_name, _open_api) do
    properties =
      schema
      |> Map.get("properties", [])
      |> Enum.sort_by(fn {name, _} -> name end)

    if Enum.empty?(properties) do
      {[], nil}
    else
      seen = seen_schema_names(schema_name, properties)

      res = typed_ecto_module(properties, schema_name)
      {seen, res}
    end
  end

  defp typed_ecto_module(properties, schema_name) do
    typed_ecto_schema = typed_ecto_schema(schema_name, properties)

    quote do
      defmodule unquote(String.to_atom("Elixir.#{schema_name}")) do
        use CommonCore, :embedded_schema

        unquote(typed_ecto_schema)
      end
    end
  end

  defp typed_ecto_schema(schema_name, properties) do
    inner = Enum.map(properties, fn prop -> field_def(schema_name, prop) end)

    quote do
      batt_embedded_schema do
        # Add each of the fields here
        # Each of the `field_defs` will be a quoted call to the `field` macro
        (unquote_splicing(inner))
      end
    end
  end

  def seen_schema_names(schema_name, properties) when schema_name not in @dont_specialize_spec_types do
    properties
    |> Enum.map(fn {_property_name, info} ->
      ref_schema_name(info)
    end)
    |> Enum.filter(fn value -> value != nil && value != schema_name end)
    |> Enum.uniq()
  end

  def seen_schema_names(_, _), do: []

  # These are typedefs for arrays. That's not a thing in ecto.
  defp ref_schema_name(%{"$ref" => "#/components/schemas/CustomerChargeFiltersUsageObject"}), do: nil
  defp ref_schema_name(%{"$ref" => "#/components/schemas/CustomerChargeGroupsUsageObject"}), do: nil
  defp ref_schema_name(%{"$ref" => "#/components/schemas/CustomerChargeGroupedUsageObject"}), do: nil

  defp ref_schema_name(%{"$ref" => ref_name}), do: ref_name_to_schema_name(ref_name)

  # Special case for Lago. The huge enums are strings
  defp ref_schema_name(%{"allOf" => [%{"$ref" => "#/components/schemas/Currency"}]}), do: nil
  defp ref_schema_name(%{"allOf" => [%{"$ref" => "#/components/schemas/Currency"}, _]}), do: nil
  defp ref_schema_name(%{"allOf" => [%{"$ref" => "#/components/schemas/Country"}]}), do: nil
  defp ref_schema_name(%{"allOf" => [%{"$ref" => "#/components/schemas/Country"}, _]}), do: nil
  defp ref_schema_name(%{"allOf" => [%{"$ref" => "#/components/schemas/Timezone"}]}), do: nil
  defp ref_schema_name(%{"allOf" => [%{"$ref" => "#/components/schemas/Timezone"}, _]}), do: nil

  defp ref_schema_name(%{"allOf" => [%{"$ref" => ref_name}]}), do: ref_name_to_schema_name(ref_name)
  defp ref_schema_name(%{"allOf" => [%{"$ref" => ref_name}, _]}), do: ref_name_to_schema_name(ref_name)

  defp ref_schema_name(%{"items" => %{"$ref" => ref_name}}), do: ref_name_to_schema_name(ref_name)

  defp ref_schema_name(%{"additionalProperties" => additional_properties}), do: ref_schema_name(additional_properties)

  defp ref_schema_name(_), do: nil

  defp ref_name_to_schema_name(ref_name) do
    case String.split(ref_name, "#/components/schemas/") do
      ["", "OAuthClientRepresentation"] -> nil
      ["", schema_name] -> schema_name
      _ -> nil
    end
  end

  defp field_def(schema_name, {field_name, %{"$ref" => _} = field_info})
       when schema_name not in @dont_specialize_spec_types do
    case ref_schema_name(field_info) do
      nil ->
        non_embed_def(field_name, field_info)

      embeded_schema_name ->
        embedded_def(field_name, embeded_schema_name)
    end
  end

  defp field_def(schema_name, {field_name, %{"type" => "array"} = field_info})
       when schema_name not in @dont_specialize_spec_types do
    case ref_schema_name(field_info) do
      nil ->
        non_embed_def(field_name, field_info)

      embeded_schema_name ->
        embedded_many_def(field_name, embeded_schema_name)
    end
  end

  defp field_def(_schema_name, {field_name, field_info}) do
    case ref_schema_name(field_info) do
      nil ->
        non_embed_def(field_name, field_info)

      embeded_schema_name ->
        embedded_many_def(field_name, embeded_schema_name)
    end
  end

  defp non_embed_def(field_name, field_info) do
    type = type(field_info)

    quote do
      field unquote(String.to_atom(field_name)), unquote(type)
    end
  end

  defp embedded_def(field_name, embeded_schema_name) do
    quote do
      embeds_one unquote(String.to_atom(field_name)),
                 unquote(String.to_atom("Elixir.#{embeded_schema_name}"))
    end
  end

  defp embedded_many_def(field_name, embeded_schema_name) do
    quote do
      embeds_many unquote(String.to_atom(field_name)),
                  unquote(String.to_atom("Elixir.#{embeded_schema_name}"))
    end
  end

  defp type(%{"type" => "object"}) do
    quote do
      :map
    end
  end

  defp type(%{"$ref" => "#/components/schemas/CustomerChargeGroupsUsageObject"} = _info) do
    quote do
      {:array, :map}
    end
  end

  defp type(%{"$ref" => "#/components/schemas/CustomerChargeGroupedUsageObject"} = _info) do
    quote do
      {:array, :map}
    end
  end

  defp type(%{"$ref" => "#/components/schemas/CustomerChargeFiltersUsageObject"} = _info) do
    quote do
      {:array, :map}
    end
  end

  defp type(%{"$ref" => _} = _info) do
    quote do
      :map
    end
  end

  # These are specializations for Lago. They special case the Currency type as a string
  # Ecto doesn't have that ability for enums.
  defp type(%{"allOf" => [%{"$ref" => "#/components/schemas/Currency"}]} = _info) do
    quote do
      :string
    end
  end

  defp type(%{"allOf" => [%{"$ref" => "#/components/schemas/Currency"}, _]} = _info) do
    quote do
      :string
    end
  end

  defp type(%{"allOf" => [%{"$ref" => "#/components/schemas/Country"}]} = _info) do
    quote do
      :string
    end
  end

  defp type(%{"allOf" => [%{"$ref" => "#/components/schemas/Country"}, _]} = _info) do
    quote do
      :string
    end
  end

  defp type(%{"allOf" => [%{"$ref" => "#/components/schemas/Timezone"}]} = _info) do
    quote do
      :string
    end
  end

  defp type(%{"allOf" => [%{"$ref" => "#/components/schemas/Timezone"}, _]} = _info) do
    quote do
      :string
    end
  end

  defp type(%{"allOf" => _} = _info) do
    quote do
      :map
    end
  end

  defp type(%{"type" => "array"} = _info) do
    quote do
      {:array, :string}
    end
  end

  defp type(%{"type" => "string"}) do
    quote do
      :string
    end
  end

  defp type(%{"type" => "number", "format" => "float"}) do
    quote do
      :float
    end
  end

  # Floats are double precision in elixir
  defp type(%{"type" => "number", "format" => "double"}) do
    quote do
      :float
    end
  end

  defp type(%{"type" => "number"}) do
    quote do
      :integer
    end
  end

  defp type(%{"type" => "int32"}) do
    quote do
      :integer
    end
  end

  defp type(%{"type" => "integer"}) do
    quote do
      :integer
    end
  end

  defp type(%{"type" => "boolean"}) do
    quote do
      :boolean
    end
  end
end
