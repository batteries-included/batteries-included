defmodule Verify.PathHelper do
  @moduledoc false

  require Logger

  @spec find_bi() :: String.t()
  def find_bi do
    override = bi_bin_override()

    if override != nil do
      Logger.info("Using BI binary override at #{override}")
      override
    else
      internal = internal_location()
      file_exists = File.exists?(internal)

      if file_exists do
        Logger.info("Using internal BI binary at #{internal}")
        internal
      else
        Logger.info("BI binary not found at #{internal}, building BI via bix ensure-bi")
        {_, 0} = System.cmd("bix", ["ensure-bi"])
        internal
      end
    end
  end

  def root_path do
    {location, 0} = System.cmd("bix", ["root-dir"])
    String.trim(location)
  end

  defp bi_bin_override, do: Application.get_env(:verify, :bi_bin_override, nil)

  defp internal_location do
    {location, 0} = System.cmd("bix", ["bi-location"])
    String.trim(location)
  end
end
