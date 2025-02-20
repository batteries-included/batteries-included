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

  describe "encrypt" do
    test "can encrypt" do
      alice = CommonCore.JWK.generate_key()
      alice_pub = JOSE.JWK.to_public(alice)

      input = %{"test" => 100}

      enc = CommonCore.JWK.encrypt(alice_pub, input)
      out = CommonCore.JWK.decrypt(alice, enc)

      assert out == input
    end

    # test "can encrypt with common core" do
    #   alice = JOSE.JWK.generate_key({:okp, :X448})
    #   alice_pub = JOSE.JWK.to_public(alice)

    #   enc = CommonCore.JWK.encrypt(alice_pub, %{test: 100})
    #   assert is_binary(enc)
    # end
  end
end
