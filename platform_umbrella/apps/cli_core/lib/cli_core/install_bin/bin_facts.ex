defmodule CLICore.InstallBin.BinFacts do
  import CLICore.InstallBin.Core

  def url(type) do
    url(type, os_type(), arch())
  end

  defp url(:kind, os, arch),
    do:
      "https://github.com/kubernetes-sigs/kind/releases/download/v0.14.0/kind-#{to_string(os)}-#{to_string(arch)}"

  defp url(:kubectl, os, arch),
    do: "https://dl.k8s.io/release/v1.25.4/bin/#{to_string(os)}/#{to_string(arch)}/kubectl"
end
