defmodule Server.FilterConfig do
  import Filtrex.Type.Config

  # create configuration for transforming / validating parameters
  def raw_configs() do
    defconfig do
      text([:path])
    end
  end
end
