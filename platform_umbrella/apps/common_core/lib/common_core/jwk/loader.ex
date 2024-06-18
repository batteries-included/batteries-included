defmodule CommonCore.JWK.Loader do
  @moduledoc false

  use CommonCore.IncludeResource,
    home_a_pub: "priv/keys/home_a.pub.pem",
    home_b_pub: "priv/keys/home_b.pub.pem",
    test_pub: "priv/keys/test.pub.pem",
    test: "priv/keys/test.pem"

  require Logger

  @callback get(key_name :: atom()) :: map() | nil
  @spec get(atom()) :: map() | nil
  def get(_)

  # The main key
  def get(:home_a_pub), do: from_resource(:home_a_pub)
  # The backup key
  def get(:home_b_pub), do: from_resource(:home_b_pub)
  # Test key used for dev and test environments
  def get(:test_pub), do: from_resource(:test_pub)
  def get(:test), do: from_resource(:test)

  def get(:home_a) do
    path = get_config_path(:home_a, "apps/common_core/priv/keys/home_a.pem")
    from_path(path)
  end

  def get(:home_b) do
    path = get_config_path(:home_b, "apps/common_core/priv/keys/home_b.pem")
    from_path(path)
  end

  def get(key_name) do
    Logger.error("Unknown key: #{inspect(key_name)}")
    nil
  end

  defp get_config_path(key_name, default) do
    :common_core
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:paths, [])
    |> Keyword.get(key_name, default)
  end

  defp from_resource(key_name) do
    key_name
    |> get_resource()
    |> JOSE.JWK.from_pem()
    |> JOSE.JWK.to_map()
    |> elem(1)
  end

  defp from_path(path) do
    if File.exists?(path) do
      path
      |> JOSE.JWK.from_pem_file()
      |> JOSE.JWK.to_map()
      |> elem(1)
    else
      Logger.error("Key file not found: #{inspect(path)}")
      nil
    end
  end
end
