defmodule CommonCore.IncludeResource do
  @moduledoc false
  @callback get_resource(file_id :: atom()) :: binary()

  defmacro __using__(opts \\ []) do
    contents = Enum.map(opts, fn {id, path} -> {id, File.read!(path)} end)

    %{module: mod} = __CALLER__
    Module.register_attribute(mod, :included_resources, accumulate: true)

    string_defs =
      Enum.map(contents, fn {id, contents} ->
        Module.put_attribute(mod, :included_resources, id)

        quote do
          defp __file_contents__(unquote(id), :string), do: unquote(contents)
        end
      end)

    quote do
      @behaviour CommonCore.IncludeResource

      unquote_splicing(string_defs)

      @doc """
      The string contents of the resource file.
      """
      def get_resource(file_id), do: __file_contents__(file_id, :string)

      # Add these methods as always being inlined.
      # The hope is that these become real compile time constants.
      @compile {:inline, get_resource: 1}
      @compile {:inline, __file_contents__: 2}
    end
  end
end
