defmodule CommonCore.Util.DefaultableField do
  @moduledoc """
  TypedEctoSchema with defaults (and PolymorphicEmbed) have a slightly strange behaviour in that the defaults are saved to the database. 

  This is generally probably not what one wants as it makes it difficult to understand if the user wanted the default or if it just defaulted.

  This module works with CommonCore.Util.PolymorphicType to provide defaultable schema fields that aren't saved to the DB.
  We accomplish this by using a virtual field and an `_override` field for each defaultable field. The `_override` field is saved to the DB.
  A simple rule of thumb is to read the virtual field and write to the `_override`.

  ## Examples

    defmodule MySchemaWithDefaultableFields do
      use CommonCore.Util.DefaultableField
      use TypedEctoSchema

      typed_schema do
        defaultable_field :a_field_with_a_default, :string, default: "the default string"
      end
    end

  """

  defmacro __using__(_opts) do
    [
      prelude()
    ]
  end

  defp prelude do
    quote do
      @before_compile {unquote(__MODULE__), :__before_compile__}

      import unquote(__MODULE__), only: [defaultable_field: 3]

      Module.register_attribute(__MODULE__, :__defaultable_field_fields, accumulate: true)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __defaulted_fields, do: @__defaultable_field_fields
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

    typed_schema do
      defaultable_field :name, :type, default: "the default"
    end

    typed_schema do
      defaultable_field :image, :string, default: "v0.0.1"
      defaultable_field :image_type, Ecto.Enum, values: [:a, :b, :c], default: :a
    end

  """
  defmacro defaultable_field(name, type, opts) do
    opts_to_pass = Enum.reject(opts, fn {opt, _val} -> opt == :default end)
    virtual_opts = [virtual: true] ++ opts_to_pass
    stored_opts = [] ++ opts_to_pass

    quote bind_quoted: [
            virtual_name: name,
            stored_name: override_name("#{name}_override"),
            type: type,
            virtual_opts: virtual_opts,
            stored_opts: stored_opts,
            default: Keyword.get(opts, :default)
          ] do
      Module.put_attribute(__MODULE__, :__defaultable_field_fields, {virtual_name, default})
      field(virtual_name, type, virtual_opts)
      field(stored_name, type, stored_opts)
    end
  end

  defp override_name(str) do
    String.to_existing_atom(str)
  rescue
    _ ->
      # credo:disable-for-next-line Credo.Check.Warning.UnsafeToAtom
      String.to_atom(str)
  end
end
