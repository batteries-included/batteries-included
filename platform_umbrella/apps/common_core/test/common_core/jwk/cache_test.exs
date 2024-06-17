defmodule CommonCore.JWK.CacheTest do
  use ExUnit.Case

  import Mox

  alias CommonCore.JWK.LoaderMock

  @fake_key %{"kty" => "test", "crv" => "yes", "x" => "0", "d" => "i"}

  setup do
    {:ok, pid} = CommonCore.JWK.Cache.start_link(name: CommonCore.JWK.CacheTest.Cache, loader: LoaderMock)
    allow(LoaderMock, self(), pid)
    {:ok, pid: pid}
  end

  describe "CommonCore.JWK.Cache" do
    test "uses the Loader to get keys", %{pid: pid} do
      expect(LoaderMock, :get, fn :home_a -> @fake_key end)
      key = CommonCore.JWK.Cache.get(pid, :home_a)
      assert key == @fake_key
    end

    test "only gets called once", %{pid: pid} do
      expect(LoaderMock, :get, 1, fn :home_a -> @fake_key end)
      key_one = CommonCore.JWK.Cache.get(pid, :home_a)
      key_two = CommonCore.JWK.Cache.get(pid, :home_a)

      assert key_one == key_two
      assert key_two == @fake_key
    end
  end
end
