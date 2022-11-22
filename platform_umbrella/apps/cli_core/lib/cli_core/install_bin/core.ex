defmodule CLICore.InstallBin.Core do
  def os_type do
    with {:unix, os_type} <- :os.type() do
      os_type
    end
  end

  def arch do
    system_arch = :system_architecture |> :erlang.system_info() |> to_string()

    cond do
      String.starts_with?(system_arch, "x86_64") -> :amd64
      String.starts_with?(system_arch, "aarch64") -> :arm64
    end
  end
end
