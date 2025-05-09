defmodule CommonCore.Defaults.Registry do
  @moduledoc false

  alias CommonCore.Defaults.Image

  defmacro __before_compile__(_env) do
    registry =
      "../../../image_registry.yaml"
      |> Path.relative_to_cwd()
      |> YamlElixir.read_from_file!()
      |> Map.new(fn {key, val} -> {String.to_atom(key), Image.new!(val)} end)

    quote do
      def registry, do: unquote(Macro.escape(registry))
    end
  end
end
