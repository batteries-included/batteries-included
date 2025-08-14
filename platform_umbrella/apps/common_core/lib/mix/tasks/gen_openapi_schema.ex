defmodule Mix.Tasks.Gen.Openapi.Schema do
  @shortdoc "Given a json schema for open api generate a module for the given stuct types using Ecto.Schema"
  @moduledoc """
  Given a json schema for open api generate a module for the given stuct types using Ecto.Schema.

  This task supports:
  - Regular object schemas with embedded schemas using Ecto.Schema
  - Enum schemas (with "enum" and "type": "string") using CommonCore.Ecto.Enum
  - Proper dependency tracking and ordering of generated modules
  - Exclusion of problematic schema types via @dont_specialize_spec_types

  Enum schemas are automatically detected and converted to keyword lists where:
  - Enum values become atoms with underscores replacing special characters
  - The original string values are preserved for serialization

  Usage:
    mix gen.openapi.schema <path> <root_schema> <module_name>

  Examples:
    mix gen.openapi.schema openapi.json "*" "MySchema"  # Generate all schemas
    mix gen.openapi.schema openapi.json "User" "UserSchema"  # Generate specific schema
  """

  use Mix.Task
  use TypedStruct

  @dont_specialize_spec_types [
    "ResourceRepresentation",
    "ResourceOwnerRepresentation",
    "ScopeRepresentation",
    "PolicyRepresentation",
    "UserManagedAccessConfig",
    "CustomerChargeFiltersUsageObject",
    "CustomerChargeGroupsUsageObject",
    "CustomerChargeGroupedUsageObject"
  ]
  @field_regex ~r/^(\s*)(field|embeds_many|embeds_one)\((.*)\)$/

  def run(args) do
    [path, root_schema, module_name] = args

    {:ok, open_api} = decode(path)

    module = module(open_api, root_schema, module_name)

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
    field :enums, map(), default: %{}
    field :enum_deps, map(), default: %{}
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
    {:ok, modules_sorted} = sorted_modules_and_enums(state)

    quote do
      defmodule unquote(module_name) do
        (unquote_splicing(modules_sorted))
      end
    end
  end

  defp sorted_modules_and_enums(state) do
    do_sorted_modules_and_enums([], state)
  end

  defp do_sorted_modules_and_enums(result, %State{modules: modules, enums: enums})
       when map_size(modules) == 0 and map_size(enums) == 0 do
    {:ok, Enum.reverse(result)}
  end

  defp do_sorted_modules_and_enums(result, %State{deps: deps, enum_deps: enum_deps} = state) do
    # Try to find an enum with no dependencies first
    enum_possible =
      Enum.find(enum_deps, fn {_enum_name, deps} -> Enum.empty?(deps) end)

    # Try to find a module with no dependencies
    module_possible =
      Enum.find(deps, fn {_schema_name, deps} -> Enum.empty?(deps) end)

    cond do
      enum_possible != nil ->
        {enum_name, _} = enum_possible
        {new_result, new_state} = add_sorted_enum(result, state, enum_name)
        do_sorted_modules_and_enums(new_result, new_state)

      module_possible != nil ->
        case module_possible do
          nil ->
            {:error, :cant_find_no_deps}

          {:single, schema_name} ->
            {new_result, new_state} = add_sorted_module(result, state, schema_name)
            do_sorted_modules_and_enums(new_result, new_state)

          {schema_name, _} ->
            {new_result, new_state} = add_sorted_module(result, state, schema_name)
            do_sorted_modules_and_enums(new_result, new_state)
        end

      true ->
        {:error, :cant_find_no_deps}
    end
  end

  defp add_sorted_enum(result, state, enum_name) do
    enum_module = Map.fetch!(state.enums, enum_name)

    new_enum_deps =
      state.enum_deps
      |> Enum.map(fn {k, deps} ->
        kept = Enum.reject(deps, &(&1 == enum_name))
        {k, kept}
      end)
      |> Enum.reject(fn {k, _v} -> k == enum_name end)
      |> Map.new()

    new_deps =
      Map.new(state.deps, fn {k, deps} ->
        kept = Enum.reject(deps, &(&1 == enum_name))
        {k, kept}
      end)

    {[enum_module | result],
     %{state | enums: Map.delete(state.enums, enum_name), enum_deps: new_enum_deps, deps: new_deps}}
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
      Map.has_key?(state.modules, schema_name) or Map.has_key?(state.enums, schema_name) ->
        state

      schema != nil and enum_schema?(schema) ->
        do_add_enum(state, open_api, schema_name, schema)

      schema != nil ->
        do_add(state, open_api, schema_name, schema)

      true ->
        state
    end
  end

  defp enum_schema?(%{"enum" => _enum_values, "type" => "string"}), do: true
  defp enum_schema?(_), do: false

  # Adds an enum schema to the state.
  #
  # Enum schemas are those with "enum" and "type": "string" properties.
  # They are converted to modules using CommonCore.Ecto.Enum.
  defp do_add_enum(state, _open_api, schema_name, schema) do
    enum_values = Map.get(schema, "enum", [])
    enum_module = enum_module_definition(schema_name, enum_values)

    %{
      state
      | enums: Map.put(state.enums, schema_name, enum_module),
        enum_deps: Map.put(state.enum_deps, schema_name, [])
    }
  end

  # Generates a module definition for an enum schema.
  #
  # Converts enum values to a keyword list where:
  # - Keys are normalized atom versions of the enum values (lowercase, underscores)
  # - Values are the original string values for proper serialization
  defp enum_module_definition(schema_name, enum_values) do
    # Convert enum values to keyword list for CommonCore.Ecto.Enum
    enum_keyword_list =
      enum_values
      |> Enum.with_index()
      |> Enum.map(fn {value, _index} ->
        atom_key =
          value
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9_]/, "_")
          |> String.to_atom()

        {atom_key, value}
      end)

    quote do
      defmodule unquote(String.to_atom("Elixir.#{schema_name}")) do
        use CommonCore.Ecto.Enum, unquote(enum_keyword_list)
      end
    end
  end

  defp do_add(state, open_api, schema_name, schema) do
    {seen, schema_module} = definition(schema, schema_name, open_api)

    with_this = %{
      state
      | modules: Map.put(state.modules, schema_name, schema_module),
        deps: Map.put(state.deps, schema_name, seen)
    }

    Enum.reduce(seen, with_this, fn seen_schema_name, latest_state ->
      add(latest_state, open_api, seen_schema_name)
    end)
  end

  defp definition(%{"oneOf" => one_of} = _schema, schema_name, open_api) do
    properties =
      one_of
      |> Enum.map(fn v -> Map.get(v, "properties", %{}) end)
      |> Enum.reduce(%{}, &Map.merge/2)
      |> Enum.sort_by(fn {name, _} -> name end)

    seen = seen_schema_names(schema_name, properties)
    res = typed_ecto_module(properties, schema_name, open_api)
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
    res = typed_ecto_module(properties, schema_name, open_api)
    {seen, res}
  end

  defp definition(%{} = schema, schema_name, open_api) do
    properties =
      schema
      |> Map.get("properties", [])
      |> Enum.sort_by(fn {name, _} -> name end)

    if Enum.empty?(properties) do
      {[], nil}
    else
      seen = seen_schema_names(schema_name, properties)

      res = typed_ecto_module(properties, schema_name, open_api)
      {seen, res}
    end
  end

  defp typed_ecto_module(properties, schema_name, open_api) do
    typed_ecto_schema = typed_ecto_schema(schema_name, properties, open_api)

    quote do
      defmodule unquote(String.to_atom("Elixir.#{schema_name}")) do
        use CommonCore, :embedded_schema

        unquote(typed_ecto_schema)
      end
    end
  end

  defp typed_ecto_schema(schema_name, properties, open_api) do
    inner = Enum.map(properties, fn prop -> field_def(schema_name, prop, open_api) end)

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
    |> Enum.filter(fn value ->
      value != nil && value != schema_name && value not in @dont_specialize_spec_types
    end)
    |> Enum.uniq()
  end

  def seen_schema_names(_, _), do: []

  # These are typedefs for arrays. That's not a thing in ecto.
  defp ref_schema_name(%{"$ref" => "#/components/schemas/CustomerChargeFiltersUsageObject"}), do: nil
  defp ref_schema_name(%{"$ref" => "#/components/schemas/CustomerChargeGroupsUsageObject"}), do: nil
  defp ref_schema_name(%{"$ref" => "#/components/schemas/CustomerChargeGroupedUsageObject"}), do: nil
  defp ref_schema_name(%{"$ref" => "#/components/schemas/MultivaluedHashMapStringComponentExportRepresentation"}), do: nil
  defp ref_schema_name(%{"$ref" => "#/components/schemas/MultivaluedHashMapStringString"}), do: nil

  defp ref_schema_name(%{"$ref" => ref_name}), do: ref_name_to_schema_name(ref_name)

  defp ref_schema_name(%{"allOf" => [%{"$ref" => ref_name}]}), do: ref_name_to_schema_name(ref_name)
  defp ref_schema_name(%{"allOf" => [%{"$ref" => ref_name}, _]}), do: ref_name_to_schema_name(ref_name)

  defp ref_schema_name(%{"items" => %{"$ref" => ref_name}}), do: ref_name_to_schema_name(ref_name)

  defp ref_schema_name(%{"additionalProperties" => additional_properties}), do: ref_schema_name(additional_properties)

  defp ref_schema_name(_), do: nil

  defp ref_name_to_schema_name(ref_name) do
    case String.split(ref_name, "#/components/schemas/") do
      ["", "OAuthClientRepresentation"] -> nil
      ["", "MultivaluedHashMapStringString"] -> nil
      ["", schema_name] -> schema_name
      _ -> nil
    end
  end

  defp field_def(schema_name, {field_name, %{"$ref" => _} = field_info}, open_api)
       when schema_name not in @dont_specialize_spec_types do
    case ref_schema_name(field_info) do
      nil ->
        non_embed_def(field_name, field_info)

      referenced_schema_name ->
        cond do
          referenced_schema_name in @dont_specialize_spec_types ->
            non_embed_def(field_name, field_info)

          enum_reference?(field_info, open_api) ->
            enum_field_def(field_name, referenced_schema_name)

          true ->
            embedded_def(field_name, referenced_schema_name)
        end
    end
  end

  defp field_def(schema_name, {field_name, %{"type" => "array"} = field_info}, open_api)
       when schema_name not in @dont_specialize_spec_types do
    case ref_schema_name(field_info) do
      nil ->
        non_embed_def(field_name, field_info)

      referenced_schema_name ->
        cond do
          referenced_schema_name in @dont_specialize_spec_types ->
            non_embed_def(field_name, field_info)

          enum_reference?(field_info, open_api) ->
            enum_array_field_def(field_name, referenced_schema_name)

          true ->
            embedded_many_def(field_name, referenced_schema_name)
        end
    end
  end

  defp field_def(_schema_name, {field_name, field_info}, open_api) do
    case ref_schema_name(field_info) do
      nil ->
        non_embed_def(field_name, field_info)

      referenced_schema_name ->
        cond do
          referenced_schema_name in @dont_specialize_spec_types ->
            non_embed_def(field_name, field_info)

          enum_reference?(field_info, open_api) ->
            enum_field_def(field_name, referenced_schema_name)

          true ->
            embedded_many_def(field_name, referenced_schema_name)
        end
    end
  end

  defp enum_reference?(%{"$ref" => ref_name}, open_api) do
    schema_name = ref_name_to_schema_name(ref_name)

    if schema_name do
      referenced_schema = get_in(open_api, ["components", "schemas", schema_name])
      referenced_schema && enum_schema?(referenced_schema)
    else
      false
    end
  end

  defp enum_reference?(%{"items" => %{"$ref" => ref_name}}, open_api) do
    schema_name = ref_name_to_schema_name(ref_name)

    if schema_name do
      referenced_schema = get_in(open_api, ["components", "schemas", schema_name])
      referenced_schema && enum_schema?(referenced_schema)
    else
      false
    end
  end

  defp enum_reference?(_, _), do: false

  # Generates a field definition for an enum type.
  #
  # Uses the enum module directly as the field type for proper validation.
  defp enum_field_def(field_name, enum_schema_name) do
    quote do
      field unquote(String.to_atom(field_name)),
            unquote(String.to_atom("Elixir.#{enum_schema_name}"))
    end
  end

  # Generates a field definition for an array of enum values.
  #
  # Uses {:array, EnumModule} as the field type.
  defp enum_array_field_def(field_name, enum_schema_name) do
    quote do
      field unquote(String.to_atom(field_name)),
            {:array, unquote(String.to_atom("Elixir.#{enum_schema_name}"))}
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

  defp type(%{"$ref" => "#/components/schemas/MultivaluedHashMapStringComponentExportRepresentation"} = _info) do
    quote do
      {:array, :map}
    end
  end

  defp type(%{"$ref" => "#/components/schemas/MultivaluedHashMapStringString"} = _info) do
    quote do
      {:array, :string}
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

  defp type(%{}) do
    quote do
      :string
    end
  end
end
