defmodule KubeExt.IniConfig do
  def to_ini(content) do
    Enum.map_join(content, "\n", &to_section/1)
  end

  defp to_section({title, content}) do
    string_content = Enum.map_join(content, "\n", &to_line/1)
    "[#{title}]\n" <> string_content <> "\n"
  end

  defp to_line({key, value}) do
    "#{key} = #{value}"
  end
end
