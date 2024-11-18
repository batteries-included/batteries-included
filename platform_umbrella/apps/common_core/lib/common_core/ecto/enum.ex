defmodule CommonCore.Ecto.Enum do
  @moduledoc false

  @spec __using__(keyword() | map()) :: Macro.t()
  defmacro __using__(input) do
    valid_map =
      input
      |> Enum.flat_map(fn {k, v} ->
        if is_atom(k) and is_binary(v), do: [{k, v}], else: []
      end)
      |> Map.new()

    valid_keys = Map.keys(valid_map)
    valid_values = Map.values(valid_map)

    type_union = type_union(valid_keys)
    backing_type = backing_type(valid_values)

    quote bind_quoted: [
            valid_keys: valid_keys,
            valid_values: valid_values,
            backing_type: backing_type,
            type_union: Macro.escape(type_union),
            valid_map: Macro.escape(valid_map)
          ] do
      # This is an ecto type
      @behaviour Ecto.Type

      # Define the type for this enum module
      @type t :: unquote(type_union)

      @spec type() :: :string | :integer
      def type, do: unquote(backing_type)

      @spec cast(term()) :: {:ok, t()} | :error

      for {atom, value} <- valid_map do
        def cast(unquote(atom)), do: {:ok, unquote(atom)}

        # Do this dance to make sure that value and atom_string are
        # not the same and defining a method twice
        for v <- Enum.uniq([value, Atom.to_string(atom)]) do
          def cast(unquote(v)), do: {:ok, unquote(atom)}
        end
      end

      def cast(_other), do: :error

      # Load comes in from the database, so no need to over specify these
      @spec load(term()) :: {:ok, t()} | no_return()
      for {atom, value} <- valid_map do
        def load(unquote(value)), do: {:ok, unquote(atom)}
      end

      def load(term) do
        msg =
          "Value `#{inspect(term)}` is not a valid enum value for `#{inspect(__MODULE__)}`. " <>
            "Valid values are `#{inspect(__valid_values__())}`"

        raise Ecto.ChangeError, message: msg
      end

      @spec dump(t() | String.t()) :: {:ok, String.t() | integer()} | no_return()
      for {atom, value} <- valid_map do
        def dump(unquote(atom)), do: {:ok, unquote(value)}

        for v <- Enum.uniq([value, Atom.to_string(atom)]) do
          def dump(unquote(v)), do: {:ok, unquote(value)}
        end
      end

      def dump(term) do
        msg =
          "Value `#{inspect(term)}` is not a valid enum value for `#{inspect(__MODULE__)}`. " <>
            "Valid values are `#{inspect(__valid_values__())}`"

        raise Ecto.ChangeError, message: msg
      end

      @spec valid_value?(term()) :: boolean()
      for valid_value <- valid_values do
        def valid_value?(unquote(valid_value)), do: true
      end

      @spec embed_as(atom()) :: :self
      def embed_as(_), do: :self

      @spec equal?(term(), term()) :: boolean()
      def equal?(term1, term2), do: term1 == term2

      def valid_value?(_), do: false

      @spec __enum_map__() :: %{atom() => String.t() | integer()}
      def __enum_map__, do: unquote(Macro.escape(valid_map))

      @spec __valid_values__() :: [String.t() | integer()]
      def __valid_values__, do: unquote(valid_values)
    end
  end

  defp type_union(valid_keys) do
    case valid_keys do
      [] ->
        quote(do: atom())

      [single] ->
        quote(do: unquote(single))

      [first | rest] ->
        Enum.reduce(rest, quote(do: unquote(first)), fn key, acc ->
          quote(do: unquote(acc) | unquote(key))
        end)
    end
  end

  defp backing_type(valid_values) do
    (Enum.all?(valid_values, &is_binary/1) && :string) ||
      (Enum.all?(valid_values, &is_integer/1) && :integer) ||
      raise ArgumentError, "All enum values must be of the same type, either all strings or all integers."
  end
end
