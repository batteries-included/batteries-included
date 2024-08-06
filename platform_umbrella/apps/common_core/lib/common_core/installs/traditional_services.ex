defmodule CommonCore.Installs.TraditionalServices do
  @moduledoc false
  alias CommonCore.Defaults.Images
  alias CommonCore.TraditionalServices.Service

  def services(%{usage: :development} = _installation) do
    [
      Service.new!(%{
        name: "home-base",
        virtual_size: "tiny",
        containers: [%{name: "home-base", image: Images.home_base_image()}],
        ports: [%{name: "http", number: 4000, protocol: :http2}]
      })
    ]
  end

  def services(%{usage: _} = _installation), do: []
end
