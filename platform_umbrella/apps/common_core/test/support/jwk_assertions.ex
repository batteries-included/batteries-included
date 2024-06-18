defmodule CommonCore.JWK.Assertions do
  @moduledoc false
  import ExUnit.Assertions

  def assert_is_public_jwk(value) do
    assert is_map(value)
    assert Map.has_key?(value, "kty")
    assert Map.has_key?(value, "crv")
    assert Map.has_key?(value, "x")
    refute Map.has_key?(value, "d")
  end

  def assert_is_private_jwk(value) do
    assert is_map(value)
    assert Map.has_key?(value, "kty")
    assert Map.has_key?(value, "crv")
    assert Map.has_key?(value, "x")
    assert Map.has_key?(value, "d")
  end
end
