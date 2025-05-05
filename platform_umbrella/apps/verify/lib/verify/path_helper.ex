defmodule Verify.PathHelper do
  @moduledoc false

  require Logger

  @spec find_bi() :: String.t()
  def find_bi do
    override = bi_bin_override()

    if override == nil do
      internal = internal_location()
      file_exists = File.exists?(internal)

      if file_exists do
        Logger.info("Using internal BI binary at #{internal}")
        internal
      else
        Logger.info("BI binary not found at #{internal}, building BI via bix go ensure-bi")
        {_, 0} = System.cmd("bix", ["go", "ensure-bi"])
        internal
      end
    else
      Logger.info("Using BI binary override at #{override}")
      override
    end
  end

  def tmp_dir! do
    System.tmp_dir!()
  end

  defp bi_bin_override, do: Application.get_env(:verify, :bi_bin_override, nil)

  defp internal_location do
    {location, 0} = System.cmd("bix", ["go", "bi-location"])
    String.trim(location)
  end
end
