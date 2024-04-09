defmodule HomeBase.CustomerInstallsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HomeBase.CustomerInstalls` context.
  """

  @doc """
  Generate a installation.
  """
  def installation_fixture(attrs \\ %{}) do
    rand_slug = 8 |> :crypto.strong_rand_bytes() |> Base.encode16()

    {:ok, installation} =
      attrs
      |> Enum.into(%{
        slug: "some-likey-unique-slug-#{rand_slug}",
        usage: :development,
        kube_provider: :kind
      })
      |> HomeBase.CustomerInstalls.create_installation()

    installation
  end
end
