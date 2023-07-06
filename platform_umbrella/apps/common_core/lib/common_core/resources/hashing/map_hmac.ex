defmodule CommonCore.Resources.Hashing.MapHMAC do
  @spec get(map()) :: binary
  def get(obj) do
    :hmac |> :crypto.mac_init(:sha3_256, key()) |> update_state(obj) |> :crypto.mac_final()
  end

  defp update_state(state, obj) when is_struct(obj) do
    update_state(state, Map.from_struct(obj))
  end

  defp update_state(state, %{} = obj) do
    obj
    |> Enum.sort_by(fn {key, _} -> key end)
    |> Enum.reduce(state, fn {key, value}, mac_state ->
      mac_state |> update_state(key) |> update_state(value)
    end)
    |> then(fn latest_mac ->
      # In order to differentiate the empty state and the nil state
      # Hash this sentinel
      update_state(latest_mac, :end_map)
    end)
  end

  defp update_state(state, value) when is_list(value) do
    value
    |> Enum.reduce(state, fn elm, mac_state ->
      update_state(mac_state, elm)
    end)
    |> then(fn latest_mac ->
      update_state(latest_mac, :end_list)
    end)
  end

  defp update_state(state, value) when is_binary(value), do: :crypto.mac_update(state, value)
  defp update_state(state, value), do: :crypto.mac_update(state, to_string(value))

  defp key do
    :common_core
    |> Application.get_env(CommonCore.Resources.Hashing, [])
    |> Keyword.get(:key, "/AVk+4bbv7B1Mnh2Rta4U/hvtF7Z3jwFkYny1RqkyiM=")
    |> Base.decode64!()
  end
end
