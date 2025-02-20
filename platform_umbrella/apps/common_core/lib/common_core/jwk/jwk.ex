defmodule CommonCore.JWK do
  @moduledoc """
  JSON Web Key (JWK) utilities.
  """
  alias CommonCore.JWK.BadKeyError
  alias CommonCore.JWK.Cache

  require Logger

  @default_curve {:ec, "P-256"}
  @sign_algo "ES256"

  @dialyzer {:nowarn_function, decrypt: 2}

  @doc """
  Generate a new JWK in a form usable for embedding into ecto rows in a map field
  """
  def generate_key do
    {%{kty: _}, result} =
      @default_curve
      |> JOSE.JWK.generate_key()
      |> JOSE.JWK.to_map()

    result
  end

  @doc """
  Given a JWK, derive the public key and return it as a map
  """
  def public_key(jwk) do
    # All of our keys are the same so assert that here.
    {%{kty: _}, result} = JOSE.JWK.to_public_map(jwk)

    result
  end

  @spec has_private_key?(nil | map()) :: boolean
  def has_private_key?(nil), do: false

  def has_private_key?(jwk) do
    # This asserts the key curve and format
    #
    # That's because assumptions are made below. If this changes
    # then inspect the code carefully.
    {%{kty: _}, result} = JOSE.JWK.to_map(jwk)

    # For this key we have two parts.
    # Assue that x is known so if d is here then
    # we have enough bits to get the private key
    Map.has_key?(result, "d")
  end

  @spec sign_key() :: atom()
  def sign_key do
    :common_core
    |> Application.get_env(CommonCore.JWK, [])
    |> Keyword.get(:sign_key, :test)
  end

  @spec verify_keys() :: list(atom)
  def verify_keys do
    :common_core
    |> Application.get_env(CommonCore.JWK, [])
    |> Keyword.get(:verify_keys, [:test_pub, :home_a_pub, :home_b_pub])
  end

  def sign(payload) do
    jwk_name = sign_key()
    jwk = Cache.get(jwk_name)

    {%{kty: _}, result} = JOSE.JWK.to_map(jwk)
    result |> JOSE.JWT.sign(%{"alg" => @sign_algo}, payload) |> elem(1)
  end

  def encrypt(for_key, payload) do
    jwk_name = sign_key()
    sign_jwk = jwk_name |> Cache.get() |> to_jwk()

    for_key = to_jwk(for_key)

    signed =
      sign_jwk
      |> JOSE.JWT.sign(%{"alg" => @sign_algo}, payload)
      |> JOSE.JWS.compact()
      |> elem(1)

    {for_key, sign_jwk}
    |> JOSE.JWE.block_encrypt(
      signed,
      %{
        "alg" => "ECDH-ES",
        "enc" => "A256GCM"
      }
    )
    |> elem(1)
  end

  def decrypt(jwk, token) do
    jwk_name = sign_key()
    sign_jwk = jwk_name |> Cache.get() |> to_jwk()

    jwk = to_jwk(jwk)

    # This line make dialyzer very upset.
    # block_encrypt accepts a tuple with two elements
    # for public keys
    #
    # However that fact is not in the dialyzer spec
    # and so it gets upset.
    case JOSE.JWE.block_decrypt({to_jwk(sign_jwk), to_jwk(jwk)}, token) do
      {:error, _} ->
        nil

      {value, _jwe} ->
        sign_jwk
        |> JOSE.JWS.verify_strict(["ES512"], value)
        |> elem(1)
        |> JSON.decode!()
    end
  end

  def verify!(nil), do: raise(BadKeyError.exception())

  def verify!(token) do
    case first_verified(token) do
      nil -> raise BadKeyError.exception()
      value -> value
    end
  end

  def verify(nil), do: {:error, BadKeyError.exception()}

  def verify(token) do
    case first_verified(token) do
      nil -> {:error, BadKeyError.exception()}
      value -> {:ok, value}
    end
  end

  defp first_verified(token) do
    Enum.find_value(verify_keys(), nil, fn key_name ->
      jwk = Cache.get(key_name)
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

  def to_jwk(%JOSE.JWK{} = jwk), do: jwk

  def to_jwk(jwk) when is_map(jwk) do
    JOSE.JWK.from_map(jwk)
  end
end
