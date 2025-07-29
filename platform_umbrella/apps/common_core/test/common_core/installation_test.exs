defmodule CommonCore.InstallationTest do
  use ExUnit.Case, async: true

  alias CommonCore.Installation

  describe "Installations can sign with elytic keys" do
    test "Installations gets keys" do
      installation = Installation.new!("signing-test", provider: :kind, usage: :development)
      assert installation.control_jwk
    end

    test "Installations can sign and verify" do
      installation = Installation.new!("signing-test", provider: :kind, usage: :development)
      data = %{"payload" => "test"}

      # Access the EC key before the installation forgets all but the public key
      jwt = installation.control_jwk |> JOSE.JWT.sign(JOSE.JWT.from(data)) |> elem(1)
      assert Installation.verify_message!(installation, jwt) == data
    end

    test "Other Installations can't verify" do
      installation_a = Installation.new!("signing-test-a", provider: :kind, usage: :development)
      installation_b = Installation.new!("signing-test-b", provider: :kind, usage: :development)
      data = %{"payload" => "test"}

      assert_raise CommonCore.JWK.BadKeyError, fn ->
        jwt = installation_a.control_jwk |> JOSE.JWT.sign(JOSE.JWT.from(data)) |> elem(1)
        Installation.verify_message!(installation_b, jwt)
      end
    end
  end
end
