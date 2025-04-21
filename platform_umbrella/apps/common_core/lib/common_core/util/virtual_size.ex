defmodule CommonCore.Util.VirtualSize do
  @moduledoc false

  def get_virtual_size(struct) do
    struct
    |> get_presets()
    |> find_matching_preset_name(struct)
  end

  defp get_presets(%{__struct__: struct}) do
    # if the __struct__ module has a presets function, call it
    if function_exported?(struct, :presets, 0) do
      struct.presets()
    else
      []
    end
  end

  defp get_presets(_), do: []

  defp find_matching_preset_name(presets, struct) do
    presets
    |> Enum.find(
      # Default to empty map if no presets match
      %{},
      fn preset ->
        # All the values in the preset must match the struct
        Enum.all?(preset, fn {k, v} ->
          k == :name || Map.get(struct, k, nil) == v
        end)
      end
    )
    |> Map.get(:name, "custom")
  end
end
