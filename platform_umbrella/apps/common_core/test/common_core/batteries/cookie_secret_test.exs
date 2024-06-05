defmodule CommonCore.Batteries.CookieSecretTest do
  @moduledoc """
  The oauth2 proxy enabled batteries need to have a specifically formatted cookie secret.
  Validate that and prevent regressions here.
  """
  use ExUnit.Case, async: true

  import CommonCore.Factory

  alias CommonCore.Resources.SSO

  @b64url_alphabet ~r"[ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789=_-]"

  # we need 32 bytes. they are b64 encoded so decode and assert
  def assert_correct_length(battery) do
    assert byte_size(Base.url_decode64!(battery.config.cookie_secret)) == 32
  end

  # replace all of the characters that are safe and we should be left with an empty string
  def assert_url_safe(battery) do
    assert String.replace(battery.config.cookie_secret, @b64url_alphabet, "") == ""
  end

  describe "cookie_secrets" do
    setup do
      batteries =
        :install_spec
        |> build(usage: :kitchen_sink, kube_provider: :aws)
        |> then(fn install_spec -> install_spec.target_summary.batteries end)
        |> Enum.filter(&Enum.member?(SSO.proxy_enabled_batteries(), &1.type))

      %{proxy_enabled_batteries: batteries}
    end

    test "are the correct length", %{proxy_enabled_batteries: batteries} do
      batteries
      |> Enum.map(&assert_correct_length/1)
      # ensure that some actions are generated
      |> then(fn bats -> assert length(bats) > 0 end)
    end

    test "are url safe", %{proxy_enabled_batteries: batteries} do
      batteries
      |> Enum.map(&assert_url_safe/1)
      # ensure that some actions are generated
      |> then(fn bats -> assert length(bats) > 0 end)
    end
  end
end
