defmodule CommonCore.Ecto.Schema do
  @moduledoc false
  require TypedEctoSchema

  defmacro __using__(_ots \\ []) do
    quote do
      use TypedEctoSchema
      @before_compile {unquote(__MODULE__), :__before_compile__}

      import CommonCore.Ecto.Schema,
        only: [
          defaultable_field: 3,
          defaultable_field: 2,
          slug_field: 2,
          slug_field: 1,
          secret_field: 2,
          secret_field: 1,
          batt_embedded_schema: 2,
          batt_embedded_schema: 1,
          batt_polymorphic_schema: 2,
          batt_schema: 3,
          batt_schema: 2
        ]

      Module.register_attribute(__MODULE__, :__defaultable_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :__generated_secrets, accumulate: true)
      Module.register_attribute(__MODULE__, :__slug_fields, accumulate: true)

      # Add some defaults
      Module.put_attribute(__MODULE__, :__polymorphic_type, nil)

      # We can't add many default methods since we
      # don't know if this is an embedded schema or a schema
      #
      # New and new! rely on the changeset method
      # Those three don't need to know the storage type
      def new(opts \\ []), do: unquote(__MODULE__).schema_new(__MODULE__, opts)
      def new!(opts \\ []), do: with({:ok, value} <- new(opts), do: value)
      def changeset(base_struct, args), do: unquote(__MODULE__).schema_changeset(base_struct, args)

      defoverridable new: 1, changeset: 2, new!: 1
    end
  end

  @doc """
  This before compile macro is adds on extra schema methods to the module that we use as our extenstions.

  ### Added

  - __schema__(:required_fields) - returns the required fields for the
  schema. These will be validated on changeset
  - __schema__(:defaultable_fields) - returns the defaultable fields for the
  schema. These will have computed values set on them
  - __schema__(:polymorphic_type) - returns the polymorphic type for the
  schema. This is used to add a type field to the schema if for polymorphic types
  - __schema__(:generated_secrets) - returns the generated secrets for
  the schema. These will have random values set on them if theres no value
  - __schema__(:slug_fields) - returns the slug fields for the schema. These will have
  a slug generated for them and validate they are valid hostname labels
  """
  defmacro __before_compile__(env) do
    quote do
      def __schema__(:required_fields), do: unquote(Module.get_attribute(env.module, :required_fields, []))
      def __schema__(:slug_fields), do: unquote(Module.get_attribute(env.module, :__slug_fields, []))
      def __schema__(:defaultable_fields), do: unquote(Module.get_attribute(env.module, :__defaultable_fields, []))
      def __schema__(:polymorphic_type), do: unquote(Module.get_attribute(env.module, :__polymorphic_type, nil))
      def __schema__(:generated_secrets), do: unquote(Module.get_attribute(env.module, :__generated_secrets, []))
    end
  end

  @doc """
  Defines a field with a default that isn't stored in the DB.

  Creates 2 fields:
    - a virtual field that defines the default. Read this field.
    - an `_override` field that is stored in the DB. Write this field.

  ##### Options
  Options are passed to the underlying schema and type.

  ##### Examples

    batt_polymorphic_schema, type: :duracell do
      defaultable_field :name, :type, default: "the default"
    end

    batt_embedded_schema do
      defaultable_field :image, :string, default: "v0.0.1"
      defaultable_field :image_type, Ecto.Enum, values: [:a, :b, :c], default: :a
    end

  """
  defmacro defaultable_field(name, type, opts \\ []) do
    opts_to_pass = Enum.reject(opts, fn {opt, _val} -> opt == :default end)
    virtual_opts = [virtual: true] ++ opts_to_pass
    stored_opts = [] ++ opts_to_pass

    ov_name = override_name("#{name}_override")

    quote bind_quoted: [
            virtual_name: name,
            stored_name: ov_name,
            type: type,
            virtual_opts: virtual_opts,
            stored_opts: stored_opts,
            default: Keyword.get(opts, :default)
          ] do
      # Store the mapping from virtual to override
      # name to default as an accumulated list of lists.
      #
      # Elixir doesn't like module attibutes being tuples so we store them as lists
      @__defaultable_fields [virtual_name, stored_name, default]

      field(virtual_name, type, virtual_opts)
      field(stored_name, type, stored_opts)
    end
  end

  defmacro secret_field(name, opts \\ []) do
    {rem_opts, opts_to_pass} = Keyword.split(opts, [:length, :func])

    field_opts = Keyword.put_new(opts_to_pass, :redact, true)

    quote bind_quoted: [name: name, opts: field_opts, validation_opts: rem_opts] do
      # Add the field name and the options to the list of generated secrets
      @__generated_secrets [name, validation_opts]

      field name, :string, opts
    end
  end

  defmacro slug_field(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @__slug_fields name

      field name, :string, opts
    end
  end

  defmacro batt_embedded_schema(opts \\ [], do: block) do
    quote do
      # This is explicitly not a polymorphic type
      @__polymorphic_type nil

      TypedEctoSchema.typed_embedded_schema(unquote(opts), do: unquote(block))

      unquote(type_impl())
    end
  end

  defmacro batt_polymorphic_schema(opts \\ [], do: block) do
    type = Keyword.fetch!(opts, :type)

    kept_opts = Keyword.delete(opts, :type)

    quote do
      Module.put_attribute(__MODULE__, :__polymorphic_type, unquote(type))
      @__polymorphic_type unquote(type)

      TypedEctoSchema.typed_embedded_schema unquote(kept_opts) do
        unquote(block)

        field :type, Ecto.Enum, values: [unquote(type)], default: unquote(type)
      end

      unquote(type_impl())
    end
  end

  defmacro batt_schema(table_name, opts \\ [], do: block) do
    quote do
      # This is explicitly not a polymorphic type
      @__polymorphic_type nil

      TypedEctoSchema.typed_schema(unquote(table_name), unquote(opts), do: unquote(block))

      # This isn't an embedded schema so
      # we can't change the dump/load/cast
    end
  end

  # Creates a new struct from the given module and applies a changeset
  # to update it with the given map.
  # Returns {:ok, struct} on success, {:error, changeset} on failure.
  @spec schema_new(module() | atom() | struct(), Keyword.t() | list() | map()) ::
          {:error, Ecto.Changeset.t()} | {:ok, map()}
  def schema_new(module, opts) do
    module
    |> struct()
    |> module.changeset(opts)
    |> Ecto.Changeset.apply_action(:update)
  end

  @spec schema_changeset(
          struct(),
          list() | map()
        ) :: struct()
  # Casts the given map to a changeset for the given base struct.
  #
  # Handles casting embedded schemas separately from regular fields.
  def schema_changeset(base, opts) do
    struct = base.__struct__

    embeds = struct.__schema__(:embeds)
    fields = struct.__schema__(:fields)
    virtual_fields = struct.__schema__(:virtual_fields)

    to_cast = Enum.concat(fields, virtual_fields) -- embeds

    changeset = Ecto.Changeset.cast(base, sanitize_opts(opts), to_cast)

    changeset =
      embeds
      |> Enum.reduce(changeset, fn embed_field, chg ->
        Ecto.Changeset.cast_embed(chg, embed_field)
      end)
      |> then(fn chg ->
        # Grab the polymorphic type if it exists
        # If its nil we don't need to do anything
        poly = struct.__schema__(:polymorphic_type)

        if poly != nil do
          # Here we explicitly add the type field to the changeset
          Ecto.Changeset.put_change(chg, :type, poly)
        else
          chg
        end
      end)

    # Add the Defaultable fields to the changeset
    changeset =
      :defaultable_fields
      |> struct.__schema__()
      |> Enum.reduce(changeset, fn [virtual_name, stored_name, default], chg ->
        # Field by field we get if the virtual field needs to be set
        # (eg it's nil and shouldn't be or it doesn't match)
        stored_value = Ecto.Changeset.get_field(chg, stored_name, nil)
        virtual_value = Ecto.Changeset.get_field(chg, virtual_name, nil)

        cond do
          stored_value != nil and virtual_value != stored_value ->
            Ecto.Changeset.put_change(chg, virtual_name, stored_value)

          virtual_value == nil and default != nil ->
            Ecto.Changeset.put_change(chg, virtual_name, default)

          true ->
            chg
        end
      end)

    # For each generated secret we check if it's nil
    # If it is we set a random value
    changeset =
      :generated_secrets
      |> struct.__schema__()
      |> Enum.reduce(changeset, fn [name, opts], chg ->
        CommonCore.Ecto.Validations.maybe_set_random(chg, name, opts)
      end)

    # Slug fields get filled in if they are blank and
    # we assume that they need to be valid DNS labels
    changeset =
      :slug_fields
      |> struct.__schema__()
      |> Enum.reduce(changeset, fn name, chg ->
        chg
        |> CommonCore.Ecto.Validations.maybe_fill_in_slug(name)
        |> CommonCore.Ecto.Validations.downcase_fields([name])
        |> CommonCore.Ecto.Validations.validate_dns_label(name)
      end)

    # Validate that required fields are there
    Ecto.Changeset.validate_required(changeset, struct.__schema__(:required_fields) || [])
  end

  @spec schema_cast(module(), map() | struct() | keyword()) ::
          {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  def schema_cast(module, data) do
    module
    |> struct()
    |> module.changeset(sanitize_opts(data))
    |> apply_changeset_if_valid()
  end

  @spec schema_dump(module(), map() | struct() | keyword()) :: {:ok, map()} | :error
  def schema_dump(module, data) do
    virtual_fields = module.__schema__(:virtual_fields)
    default_virt_fields = :defaultable_fields |> module.__schema__() |> Enum.map(fn [vf, _, _] -> vf end)

    {:ok,
     data
     |> sanitize_opts()
     |> Map.drop(virtual_fields ++ default_virt_fields)}
  end

  @spec schema_load(module(), map() | struct() | keyword()) ::
          {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  def schema_load(module, data) do
    module
    |> struct()
    |> module.changeset(data)
    |> apply_changeset_if_valid()
  end

  defp override_name(str) do
    String.to_existing_atom(str)
  rescue
    _ ->
      # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
      String.to_atom(str)
  end

  # Ecto really wants to take in raw maps.
  # It doesn't want a keyword list
  # It doesn't want values of embedded fields to be structs
  #
  # So the below allows us to take in a map or a keyword list
  # then all the values are converted to maps deeply before
  # returning a map for Ecto.Changeset to work with.
  defp sanitize_opts(opts) do
    opts
    |> ensure_map()
    |> Map.new()
  end

  defp ensure_map(value) when is_list(value) do
    Enum.map(value, &ensure_map/1)
  end

  defp ensure_map(value) when is_struct(value) do
    # TODO: This should use the dump method if it exists
    value
    |> Map.from_struct()
    |> ensure_map()
  end

  defp ensure_map(%{} = value) do
    Map.new(value, fn {key, value} -> {key, ensure_map(value)} end)
  end

  defp ensure_map(value), do: value

  @spec apply_changeset_if_valid(Ecto.Changeset.t()) :: {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  defp apply_changeset_if_valid(cs) do
    case cs do
      %Ecto.Changeset{valid?: true} ->
        {:ok, Ecto.Changeset.apply_changes(cs)}

      _ ->
        :error
    end
  end

  # This is the default Ecto.Type implementation.
  # It delegates to CommonCore.Ecto.Schema for schema_cast, schema_dump, and schema_load.
  defp type_impl do
    quote do
      @behaviour Ecto.Type

      @impl Ecto.Type
      def type, do: :map

      @impl Ecto.Type
      def cast(data), do: unquote(__MODULE__).schema_cast(__MODULE__, data)

      @impl Ecto.Type
      def dump(data), do: unquote(__MODULE__).schema_dump(__MODULE__, data)

      @impl Ecto.Type
      def load(data), do: unquote(__MODULE__).schema_load(__MODULE__, data)

      @impl Ecto.Type
      def embed_as(_), do: :self

      @impl Ecto.Type
      def equal?(term1, term2), do: term1 == term2

      defoverridable Ecto.Type
    end
  end
end
