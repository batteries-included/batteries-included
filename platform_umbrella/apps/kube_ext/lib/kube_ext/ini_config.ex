defmodule KubeExt.IniConfig do
  def to_ini(map) do
    map |> Enum.map(&to_section/1) |> Enum.join("\n")
  end

  defp to_section({title, content}) do
    string_content = content |> Enum.map(&to_line/1) |> Enum.join("\n")
    "[#{title}]\n" <> string_content <> "\n"
  end

  defp to_line({key, value}) do
    "#{key} = #{value}"
  end
end
