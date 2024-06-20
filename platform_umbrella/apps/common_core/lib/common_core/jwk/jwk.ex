defmodule CommonCore.JWK do
  @moduledoc """
  JSON Web Key (JWK) utilities.
  """
  require Logger

  @default_curve {:okp, :Ed25519}

  @doc """
  Generate a new JWK in a form usable for embedding into ecto rows in a map field
  """
  def generate_key do
    @default_curve
    |> JOSE.JWK.generate_key()
    |> JOSE.JWK.to_map()
    |> elem(1)
  end

  @doc """
  Given a JWK, derive the public key and return it as a map
  """
  def public_key(jwk) do
    jwk
    |> JOSE.JWK.to_public_map()
    |> elem(1)
  end

  @spec sign_key() :: atom()
  def sign_key do
    __MODULE__
    |> Application.get_env(CommonCore.JWK, [])
    |> Keyword.get(:sign_key, :test)
  end

  @spec verify_keys() :: list(atom)
  def verify_keys do
    __MODULE__
    |> Application.get_env(CommonCore.JWK, [])
    |> Keyword.get(:verify_keys, [:test_pub, :home_a_pub, :home_b_pub])
  end

  def sign(payload) do
    jwk_name = sign_key()
    jwk = CommonCore.JWK.Cache.get(jwk_name)
    jwk |> JOSE.JWT.sign(payload) |> elem(1)
  end

  def verify!(nil), do: raise(CommonCore.JWK.BadKeyError.exception())

  def verify!(token) do
    case first_verified(token) do
      nil -> raise CommonCore.JWK.BadKeyError.exception()
      value -> value
    end
  end

  def verify(nil), do: {:error, CommonCore.JWK.BadKeyError.exception()}

  def verify(token) do
    case first_verified(token) do
      nil -> {:error, CommonCore.JWK.BadKeyError.exception()}
      value -> {:ok, value}
    end
  end

  defp first_verified(token) do
    Enum.find_value(verify_keys(), nil, fn key_name ->
      jwk = CommonCore.JWK.Cache.get(key_name)
      try_verify_single(jwk, token)
    end)
  end

  # Get can return nil for private keys that are not present
  defp try_verify_single(nil, _token), do: nil

  defp try_verify_single(jwk, token) do
    case JOSE.JWT.verify(jwk, token) do
      {true, value, _} -> value |> JOSE.JWT.to_map() |> elem(1)
      # - This is a backup key and we are not expecting it to be used
      # - The keys are being rotated
      # - The key is not present
      _ -> nil
    end
  end
end
