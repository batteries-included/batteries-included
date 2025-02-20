defmodule CommonCore.JWK.CacheTest do
  use ExUnit.Case

  import Mox

  alias CommonCore.JWK.Cache
  alias CommonCore.JWK.LoaderMock

  @fake_key %{"kty" => "test", "crv" => "yes", "x" => "0", "d" => "i"}

  setup do
    {:ok, pid} = Cache.start_link(name: CommonCore.JWK.CacheTest.Cache, loader: LoaderMock)
    allow(LoaderMock, self(), pid)
    {:ok, pid: pid}
  end

  describe "CommonCore.JWK.Cache" do
    test "uses the Loader to get keys", %{pid: pid} do
      expect(LoaderMock, :get, fn :home_a -> @fake_key end)
      key = Cache.get(pid, :home_a)
      assert key == @fake_key
    end

    test "only gets called once", %{pid: pid} do
      expect(LoaderMock, :get, 1, fn :home_a -> @fake_key end)
      key_one = Cache.get(pid, :home_a)
      key_two = Cache.get(pid, :home_a)

      assert key_one == key_two
      assert key_two == @fake_key
    end
  end
end
