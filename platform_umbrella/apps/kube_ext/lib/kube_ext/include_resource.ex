defmodule KubeExt.IncludeResource do
  @callback get_resource(file_id :: atom()) :: binary()

  defmacro __using__(opts \\ []) do
    contents = Enum.map(opts, fn {id, path} -> {id, File.read!(path)} end)

    string_defs =
      Enum.map(contents, fn {id, contents} ->
        quote do
          defp __file_contents__(unquote(id), :string), do: unquote(contents)
        end
      end)

    quote do
      @behaviour KubeExt.IncludeResource

      unquote_splicing(string_defs)

      @doc """
      The string contents of the resource file.
      """
      def get_resource(file_id), do: __file_contents__(file_id, :string)
    end
  end
end
