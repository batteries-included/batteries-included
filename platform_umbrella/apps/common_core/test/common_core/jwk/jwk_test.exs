defmodule CommonCore.JwkTest do
  use ExUnit.Case

  import CommonCore.JWK.Assertions

  describe "CommonCore.JWK.generate_key/0" do
    test "Creates a map with expected keys" do
      key = CommonCore.JWK.generate_key()
      assert_is_private_jwk(key)
    end
  end

  describe "CommonCore.JWK.public_key/1" do
    test "Creates a map with expected keys" do
      key = CommonCore.JWK.generate_key()
      assert_is_private_jwk(key)
      public_key = CommonCore.JWK.public_key(key)
      assert_is_public_jwk(public_key)
    end
  end
end
