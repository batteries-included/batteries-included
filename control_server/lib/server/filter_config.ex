defmodule Server.FilterConfig do
  @moduledoc """
  Filtering module via Filtrex
  """
  import Filtrex.Type.Config

  # create configuration for transforming / validating parameters
  def raw_configs do
    defconfig do
      text([:path])
    end
  end
end
