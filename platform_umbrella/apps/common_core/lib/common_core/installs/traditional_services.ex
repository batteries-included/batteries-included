defmodule CommonCore.Installs.TraditionalServices do
  @moduledoc false
  alias CommonCore.Defaults.Images
  alias CommonCore.TraditionalServices.Service

  def services(%{usage: :internal_int_test} = installation) do
    [
      Service.new!(%{
        name: "home-base",
        virtual_size: install_size(installation),
        containers: [%{name: "home-base", image: Images.home_base_image()}],
        ports: [%{name: "http", number: 4000, protocol: :http2}]
      })
    ]
  end

  def services(%{usage: _} = _installation), do: []

  # The install sizes and service sizes match up but they may? not always
  defp install_size(install), do: Atom.to_string(install.default_size)
end
