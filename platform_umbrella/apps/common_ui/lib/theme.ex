defmodule CommonUI.Theme do
  @theme [
    button: [
      default: [
        background: "bg-white border border-gray-300",
        text: "text-base font-medium text-gray-700",
        focus: "focus:outline-none focus:ring-3 focus:ring-opacity-80 focus:ring-pink-500",
        hover: "hover:bg-gray-50 hover:border-pink-500",
        structure: "px-4 py-2 rounded-md shadow-sm "
      ],
      primary: [
        background: "bg-pink-500 border-1 border-gray-300",
        text: "text-base font-medium text-white",
        focus: "focus:outline-none focus:ring-3 focus:ring-opacity-80 focus:ring-white",
        hover: "hover:bg-pink-800 hover:border-gray-900",
        structure: "px-4 py-2 rounded-md shadow-sm"
      ]
    ]
  ]

  def component(component_name, theme_name \\ :default) do
    all_themes = Keyword.get(@theme, component_name, [])
    Keyword.get(all_themes, theme_name, [])
  end

  def value(component_name), do: get_value(component_name, :default)

  def value(component_name, theme) when is_binary(theme) do
    get_value(component_name, String.to_existing_atom(theme))
  end

  def value(component_name, theme) when is_atom(theme) do
    get_value(component_name, theme)
  end

  defp get_value(component_name, theme) do
    component_name |> component(theme) |> Keyword.values() |> Enum.join(" ")
  end
end
