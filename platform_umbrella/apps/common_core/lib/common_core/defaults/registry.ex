defmodule CommonCore.Defaults.Registry do
  @moduledoc false

  alias CommonCore.Defaults.Image

  defmacro __before_compile__(_env) do
    registry_file = Path.relative_to_cwd("../../../image_registry.yaml")
    registry_hash = registry_file |> File.read!() |> :erlang.md5()

    registry =
      registry_file
      |> YamlElixir.read_from_file!()
      |> Map.new(fn {key, val} -> {String.to_atom(key), Image.new!(val)} end)

    quote do
      # elixir will recompile this module if this file changes
      @external_resource unquote(registry_file)

      def registry, do: unquote(Macro.escape(registry))

      # we'll also recompile if the hash changes
      def __mix_recompile__?, do: unquote(registry_file) |> File.read!() |> :erlang.md5() !== unquote(registry_hash)
    end
  end
end
