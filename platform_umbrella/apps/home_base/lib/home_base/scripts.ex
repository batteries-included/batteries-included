defmodule HomeBase.Scripts do
  @moduledoc false

  use CommonCore.IncludeResource,
    install_bi: "priv/raw_files/install_bi.sh",
    start_local: "priv/raw_files/start_local.sh"

  alias CommonCore.Defaults.Versions

  require EEx

  EEx.function_from_file(:defp, :render_common, "priv/raw_files/common.sh", [:version])
  EEx.function_from_file(:defp, :render_start_install, "priv/raw_files/start_install.sh", [:spec_url])

  def install_bi do
    bi_version = Versions.bi_stable_version()

    common = render_common(bi_version)
    install_bi = get_resource(:install_bi)

    common <> "\n" <> install_bi
  end

  def start_local do
    bi_version = Versions.bi_stable_version()

    common = render_common(bi_version)
    start_local = get_resource(:start_local)

    common <> "\n" <> start_local
  end

  def start_install(install_spec_url) do
    bi_version = Versions.bi_stable_version()

    common = render_common(bi_version)
    start_install = render_start_install(install_spec_url)

    common <> "\n" <> start_install
  end
end
