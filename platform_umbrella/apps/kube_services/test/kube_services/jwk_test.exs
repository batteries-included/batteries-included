defmodule KubeServices.JwkTest do
  use ExUnit.Case, async: true

  describe "HomeBaseClient" do
    test "can encrypt" do
      alice = CommonCore.JWK.generate_key()

      state = KubeServices.ET.HomeBaseClient.State.new!(control_jwk: alice)
      input = %{"test" => 100}

      enc = KubeServices.ET.HomeBaseClient.encrypt(state, input)
      out = CommonCore.JWK.decrypt(JOSE.JWK.to_public(state.control_jwk), enc)

      assert out == input
    end
  end
end
