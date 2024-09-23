defmodule CommonCore.JWK.Loader do
  @moduledoc false

  use CommonCore.IncludeResource,
    home_a_pub: "priv/keys/home_a.pub.pem",
    home_b_pub: "priv/keys/home_b.pub.pem",
    test_pub: "priv/keys/test.pub.pem",
    test: "priv/keys/test.pem"

  require Logger

  @env_name "HOME_JWK"

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

  def get(:environment) do
    # Get the environment key

    string_value =
      System.get_env(@env_name)

    if string_value && !string_value != "" do
      string_value
      |> JOSE.JWK.from_binary()
      |> to_map()
    end
  end

  def get(key_name) do
    Logger.error("Unknown key: #{inspect(key_name)}")
    nil
  end

  defp from_resource(key_name) do
    key_name
    |> get_resource()
    |> JOSE.JWK.from_pem()
    |> to_map()
  end

  defp to_map(res) when is_list(res), do: res |> List.first() |> to_map()

  defp to_map(nil), do: nil

  defp to_map(jwk) do
    jwk
    |> JOSE.JWK.to_map()
    |> elem(1)
  end
end
