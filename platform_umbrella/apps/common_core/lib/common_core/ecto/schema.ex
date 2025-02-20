defmodule CommonCore.Ecto.Schema do
  @moduledoc """
  `CommonCore.Ecto.Schema` is a base schema module that provides
  additional features to Ecto schemas. Most users will want
  to use `CommonCore` instead of this module directly.

  ## Features

  - Defaultable fields: Fields that have a default value that isn't stored in the database.
  - Secret fields: Fields that get a unique value each time they are used.
  - Slug fields: Fields that have a slug generated for them and validate they are valid hostname labels.
  - Polymorphic schemas: Schemas that can take on different forms based on the given type.
  - Embedded schemas: Schemas that are embedded within another schema.
  - Required fields: Fields that are required for the schema.
  - Generated default methods: `new`, `new!`, and `changeset` are generated for the schema.

  ## Usage

  ### Normal Schema

  ```elixir
  defmodule MyApp.User do
    use CommonCore, :schema

    batt_schema "user" do
      defaultable_field :name, :string, default: "john_doe"
      secret_field :password
    end
  end
  ```

  ### Embedded Schema

  ```elixir
  defmodule MyApp.Container do
    use CommonCore, :embedded_schema

    @required_fields [:name]
    batt_embedded_schema do
      slug_field :name
      defaultable_field :overridable_thing, :string, default: "this is overrideable and not stored in DB"
      secret_field :token
    end
  end
  ```

  ### Field Types

  #### `@required_fields`

  A list of fields that are required for the schema. On any schema with this
  attribute, the fields will be validated by `validate_required/2`
  inside `CommonCore.Ecto.Schema.schema_changeset/2`.


  ### `@read_only_fields`

  A list of fields that are read only for the schema. On any schema with this
  attribute, the fields will be validated by `CommonCore.Ecto.Schema.validate_read_only/2`

  #### Defaultable Fields

  ```elixir
  defaultable_field :name, :string, default: "jason"
  ```

  This creates two fields on the schema:
    - `name` - a virtual field that defines the default. Read this field.
    - `name_override` - an `_override` field that is stored in the DB. Write this field.

  Since name_override doesn't get the default value written to it, the default value can
  be changed by updating to a new version of the schema.

  #### Defaultable Image Fields

  ```elixir
  defaultable_image_field :image,
    default_name: "public.ecr.aws/doohickey",
    tags: ~w(v1.2.3 v1.2.4)a,
    default_tag: :"v1.2.4"
  ```

  This creates the following fields on the schema:
    - `image` - a virtual field that defines the image with both name and tag. Read this field.
    - `image_name_override` - an `_override` image name field that is stored in the DB. Write this field.
    - `image_tag_override` - an `_override` image tag field that is stored in the DB. Write this field.

  Since the override fields doesn't get the default value written to it, the default value can
  be changed by updating to a new version of the schema. This is useful for us when we have
  default versions of software that we want to offer. However customers will want to
  be able to pin to a specific version until a bug is fixed or they are ready to upgrade.

  #### Secret Fields

  ```elixir
  secret_field :password
  ```

  This creates a string field on the schema that is
  redacted when it is returned. It's also filled in with a secure random
  password value if it's nil.

  #### Slug Fields

  ```elixir
  slug_field :url
  ```

  This creates a string field on the schema that is validated to be
  a valid DNS label. It's also filled in with a slugified version of
  the value if it's nil.

  #### Polymorphic Schemas

  There are times when you have a schema that contain a known
  set of payloads. There could be a lot of these and we don't want a
  table and a join to be required for every one.

  For this we offer `CommonCore.Ecto.PolymorphicType`.

  When combined with `CommonCore.Ecto.Schema` you can create a schema with a polymorphic type.


  ```elixir
  defmodule MyApp do
    defmodule FooSchema do
      use CommonCore, :embedded_schema

      batt_polymorphic_schema type: :foo do
        defaultable_field :image, :string, default: "foo:latest"
        field :other_setting, :integer, default: 1
      end
    end

    defmodule BarSchema do
      use CommonCore, :embedded_schema

      batt_polymorphic_schema type: :bar do
        defaultable_field :image, :string, default: "bar:latest"
        field :bar_setting, :integer, default: 2
      end
    end

    defmodule RootSchema do
      use CommonCore, :schema

      alias CommonCore.Ecto.PolymorphicType

      batt_schema type: :my_type do
        slug_field :name
        field :payload, PolymorphicType, mappings: [
          foo: FooSchmea,
          bar: BarSchema
        ]
      end
    end
  end
  ```
  """
  import CommonCore.Ecto.Validations

  alias Ecto.Changeset

  require TypedEctoSchema

  defmacro __using__(_ots \\ []) do
    quote do
      use TypedEctoSchema

      import CommonCore.Ecto.Schema,
        only: [
          defaultable_field: 3,
          defaultable_field: 2,
          defaultable_image_field: 2,
          defaultable_image_field: 1,
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

      import CommonCore.Ecto.Validations
      import Ecto.Changeset
      import Ecto.Query

      @before_compile {unquote(__MODULE__), :__before_compile__}

      Module.register_attribute(__MODULE__, :__defaultable_fields, accumulate: true)
      Module.register_attribute(__MODULE__, :__defaultable_image_fields, accumulate: true)
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

      def new!(opts \\ []) do
        case new(opts) do
          {:ok, value} ->
            value

          {:error, error} ->
            raise "#{inspect(error)}"
        end
      end

      def changeset(base_struct, args, opts \\ []), do: unquote(__MODULE__).schema_changeset(base_struct, args, opts)

      defoverridable new: 0, new: 1, changeset: 3, changeset: 2, new!: 1
    end
  end

  @doc """
  This before compile macro is adds on extra schema methods to the module that we use as our extenstions.

  ### Added Introspetion Methods

  - __schema__(:required_fields) - returns the required fields for the
  schema. These will be validated on changeset
  - __schema__(:defaultable_fields) - returns the defaultable fields for the
  schema. These will have computed values set on them
  - __schema__(:defaultable_image_fields) - returns the defaultable image fields for the
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

      def __schema__(:defaultable_image_fields),
        do: unquote(Module.get_attribute(env.module, :__defaultable_image_fields, []))

      def __schema__(:polymorphic_type), do: unquote(Module.get_attribute(env.module, :__polymorphic_type, nil))
      def __schema__(:generated_secrets), do: unquote(Module.get_attribute(env.module, :__generated_secrets, []))
      def __schema__(:read_only_fields), do: unquote(Module.get_attribute(env.module, :read_only_fields, []))
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
      defaultable_field :version, :string, default: "v0.0.1"
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

  @doc """
  Defines an image field with default name and tag that isn't stored in the DB.

  Creates 3 fields:
    - virtual field that defines the full image. Read this field.
    - `_override` fields for the name and tag that is stored in the DB. Write these fields.

  ##### Examples

    batt_polymorphic_schema, type: :duracell do
      defaultable_image_field :name,
        default_name: "base",
        default_tag: "default version"
    end

    batt_embedded_schema do
      defaultable_image_field :my_image,
        default_name: "public.ecr.aws/my-image",
        default_tag: :"v1.2.3"
    end

  """
  defmacro defaultable_image_field(field, opts \\ []) do
    parsed_opts = parse_defaultable_image_opts(field, opts)

    quote bind_quoted: [
            field: field,
            name_ov: parsed_opts.name_ov,
            tag_ov: parsed_opts.tag_ov,
            name_default: parsed_opts.name_default,
            tag_default: parsed_opts.tag_default
          ] do
      # Store the mapping from virtual to override
      # name to default as an accumulated list of lists.
      #
      # Elixir doesn't like module attibutes being tuples so we store them as lists
      @__defaultable_image_fields [field, name_default, tag_default]

      # virtual field to store full image name
      field(field, :string, virtual: true)
      # override for name
      field(name_ov, :string)
      # override for tag
      field(tag_ov, :string)
    end
  end

  defp parse_defaultable_image_opts(field, opts) do
    base = %{
      name_ov: override_name("#{field}_name_override"),
      tag_ov: override_name("#{field}_tag_override")
    }

    parsed =
      case Keyword.get(opts, :image_id, nil) do
        # else parse from passed opts
        nil ->
          %{
            name_default: Keyword.fetch!(opts, :default_name),
            tag_default: Keyword.fetch!(opts, :default_tag)
          }

        # if using image registry, look up values from image from registry
        id ->
          image = CommonCore.Defaults.Images.get_image!(id)

          %{
            name_default: image.name,
            tag_default: image.default_tag
          }
      end

    Map.merge(base, parsed)
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
          {:error, Ecto.Changeset.t()} | {:ok, struct()}
  def schema_new(module, opts) do
    module
    |> struct()
    |> module.changeset(opts, action: :new)
    |> Ecto.Changeset.apply_action(:insert)
  end

  @spec schema_changeset(
          struct(),
          list() | Keyword.t()
        ) :: struct()
  # Casts the given map to a changeset for the given base struct.
  #
  # Handles casting embedded schemas separately from regular fields.
  def schema_changeset(base, params, opts \\ []) do
    struct = base.__struct__

    embeds = struct.__schema__(:embeds)
    fields = struct.__schema__(:fields)
    virtual_fields = struct.__schema__(:virtual_fields)

    to_cast = Enum.concat(fields, virtual_fields) -- embeds
    cast_opts = Keyword.get(opts, :cast_opts, [])
    cast_embed_opts = Keyword.get(opts, :cast_embed_opts, [])

    changeset = Ecto.Changeset.cast(base, sanitize_opts(params), to_cast, cast_opts)

    action = Keyword.get(opts, :action, nil)

    changeset =
      if action do
        %{changeset | action: action}
      else
        changeset
      end

    changeset
    |> add_embeds(struct, cast_embed_opts)
    |> add_polymorphic_fields(struct)
    |> add_defaultable_fields(struct)
    |> add_defaultable_image_fields(struct)
    |> add_generated_secret_values(struct)
    |> add_slug_field_validations(struct)
    |> add_foreign_key_constraints(struct)
    |> add_required_fields(struct)
    |> add_read_only_fields(struct)
  end

  defp add_embeds(changeset, struct, opts) do
    embeds = struct.__schema__(:embeds)

    Enum.reduce(embeds, changeset, fn embed_field, chg ->
      Ecto.Changeset.cast_embed(chg, embed_field, opts)
    end)
  end

  defp add_polymorphic_fields(changeset, struct) do
    # Grab the polymorphic type if it exists
    # If its nil we don't need to do anything
    poly = struct.__schema__(:polymorphic_type)

    if poly == nil do
      changeset
    else
      Ecto.Changeset.put_change(changeset, :type, poly)
    end
  end

  defp add_defaultable_fields(changeset, struct) do
    :defaultable_fields
    |> struct.__schema__()
    |> Enum.reduce(changeset, fn [virtual_name, stored_name, default], chg ->
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
  end

  defp add_defaultable_image_fields(changeset, struct) do
    :defaultable_image_fields
    |> struct.__schema__()
    |> Enum.reduce(changeset, fn [virt_field, name_default, tag_default], chg ->
      stored_name = Ecto.Changeset.get_field(chg, override_name("#{virt_field}_name_override"), nil)
      stored_tag = Ecto.Changeset.get_field(chg, override_name("#{virt_field}_tag_override"), nil)
      desired_image = determine_image_string(stored_name, stored_tag, name_default, tag_default)

      Ecto.Changeset.put_change(chg, virt_field, desired_image)
    end)
  end

  defp determine_image_string(name_override, tag_override, name_default, tag_default)
  defp determine_image_string(nil, nil, name_default, tag_default), do: "#{name_default}:#{tag_default}"
  defp determine_image_string(name_ov, nil, _name_default, tag_default), do: "#{name_ov}:#{tag_default}"
  defp determine_image_string(nil, tag_ov, name_default, _tag_default), do: "#{name_default}:#{tag_ov}"
  defp determine_image_string(name_ov, tag_ov, _name_default, _tag_default), do: "#{name_ov}:#{tag_ov}"

  defp add_generated_secret_values(changeset, struct) do
    :generated_secrets
    |> struct.__schema__()
    |> Enum.reduce(changeset, fn [name, opts], chg ->
      maybe_set_random(chg, name, opts)
    end)
  end

  defp add_slug_field_validations(changeset, struct) do
    :slug_fields
    |> struct.__schema__()
    |> Enum.reduce(changeset, fn name, chg ->
      chg
      |> maybe_fill_in_slug(name)
      |> downcase_fields([name])
      |> trim_fields([name])
      |> validate_dns_label(name)
    end)
  end

  defp add_foreign_key_constraints(changeset, struct) do
    :associations
    |> struct.__schema__()
    |> Enum.reduce(changeset, fn field, chg ->
      case struct.__schema__(:association, field) do
        %Ecto.Association.BelongsTo{owner_key: owner_field} ->
          Ecto.Changeset.foreign_key_constraint(chg, owner_field)

        _ ->
          chg
      end
    end)
  end

  defp add_required_fields(changeset, struct) do
    Ecto.Changeset.validate_required(changeset, struct.__schema__(:required_fields) || [])
  end

  defp add_read_only_fields(changeset, struct) do
    CommonCore.Ecto.Validations.validate_read_only(changeset, struct.__schema__(:read_only_fields) || [])
  end

  @spec schema_cast(module(), map() | struct() | keyword()) ::
          {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  def schema_cast(module, data) do
    module
    |> struct()
    |> module.changeset(sanitize_opts(data), action: :cast)
    |> apply_changeset_if_valid()
  end

  @spec schema_dump(module(), map() | struct() | keyword()) :: {:ok, map()} | :error
  def schema_dump(module, data) do
    virtual_fields = module.__schema__(:virtual_fields)
    default_virt_fields = :defaultable_fields |> module.__schema__() |> Enum.map(fn [vf, _, _] -> vf end)
    default_virt_image_fields = :defaultable_image_fields |> module.__schema__() |> Enum.map(fn [vf, _, _] -> vf end)

    {:ok,
     data
     |> sanitize_opts()
     |> Map.drop(virtual_fields ++ default_virt_fields ++ default_virt_image_fields)}
  end

  @spec schema_load(module(), map() | struct() | keyword()) ::
          {:ok, Ecto.Schema.t() | Ecto.Changeset.data()} | :error
  def schema_load(module, data) do
    module
    |> struct()
    |> module.changeset(data, action: :load)
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
