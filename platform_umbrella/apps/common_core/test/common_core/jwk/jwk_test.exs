defmodule CommonCore.JwkTest do
  use ExUnit.Case

  import CommonCore.JWK.Assertions

  alias CommonCore.JWK.BadKeyError

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

  describe "encrypt_to_home_base/2 and decrypt_from_control_server!/2" do
    test "are mirror images" do
      alice = CommonCore.JWK.generate_key()
      alice_pub = JOSE.JWK.to_public(alice)

      input = %{"test" => 100}

      enc = CommonCore.JWK.encrypt_to_home_base(alice, input)
      out = CommonCore.JWK.decrypt_from_control_server!(alice_pub, enc)

      assert out == input
    end

    test "raises on invalid key" do
      alice = CommonCore.JWK.generate_key()

      bob = CommonCore.JWK.generate_key()
      bob_pub = JOSE.JWK.to_public(bob)

      input = %{"test" => 100}

      enc = CommonCore.JWK.encrypt_to_home_base(alice, input)

      assert_raise BadKeyError, fn ->
        CommonCore.JWK.decrypt_from_control_server!(bob_pub, enc)
      end
    end
  end

  describe "encrypt_to_control_server/2 and decrypt_from_home_base!/2" do
    test "are mirror images" do
      alice = CommonCore.JWK.generate_key()
      alice_pub = JOSE.JWK.to_public(alice)

      input = %{"test" => 100}

      enc = CommonCore.JWK.encrypt_to_control_server(alice_pub, input)
      out = CommonCore.JWK.decrypt_from_home_base!(alice, enc)

      assert out == input
    end
  end
end
