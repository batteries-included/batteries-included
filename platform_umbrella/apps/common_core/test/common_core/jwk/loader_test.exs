defmodule CommonCore.JWK.LoaderTest do
  use ExUnit.Case

  import CommonCore.JWK.Assertions

  alias CommonCore.JWK.Loader

  describe "CommonCore.JWK.Loader.get" do
    test "gets the home_a_pub key" do
      key = Loader.get(:home_a_pub)
      assert_is_public_jwk(key)
    end

    test "gets the home_b_pub key" do
      key = Loader.get(:home_b_pub)
      assert_is_public_jwk(key)
    end

    test "gets the test_pub key" do
      key = Loader.get(:test_pub)
      assert_is_public_jwk(key)
    end

    test "gets the test key" do
      key = Loader.get(:test)
      assert_is_private_jwk(key)
    end
  end
end
