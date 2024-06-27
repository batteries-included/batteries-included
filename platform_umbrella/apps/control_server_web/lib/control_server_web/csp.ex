defmodule ControlServerWeb.CSP do
  @moduledoc false
  @default_allowed %{
    "script-src" => [
      "self",
      "unsafe-eval",
      "unsafe-inline",
      {:url, "http://*.batrsinc.co"},
      {:url, "http://*.batrsinc.co:4000"},
      {:url, "http://*.batteriesincl.com"},
      {:url, "http://*.ip.batteriesincl.com:4100"}
    ],
    "default-src" => [
      "self",
      "unsafe-inline",
      {:url, "http://*.batrsinc.co"},
      {:url, "http://*.batrsinc.co:4000"},
      {:url, "http://*.batteriesincl.com"},
      {:url, "http://*.ip.batteriesincl.com:4100"}
    ],
    "img-src" => [
      "self",
      {:url, "data:"},
      {:url, "http://*.batrsinc.co"},
      {:url, "http://*.batrsinc.co:4000"},
      {:url, "http://*.batteriesincl.com"},
      {:url, "http://*.ip.batteriesincl.com:4100"}
    ],
    "font-src" => [
      "self",
      {:url, "data:"},
      {:url, "http://*.batrsinc.co"},
      {:url, "http://*.batrsinc.co:4000"},
      {:url, "http://*.batteriesincl.com"},
      {:url, "http://*.ip.batteriesincl.com:4100"}
    ],
    "frame-src" => [
      "self",
      {:url, "http://*.batrsinc.co"},
      {:url, "http://*.batrsinc.co:4000"},
      {:url, "http://*.batteriesincl.com"},
      {:url, "http://*.ip.batteriesincl.com:4100"},
      {:url, "https://www.youtube.com"}
    ]
  }

  def new(allowed \\ @default_allowed) do
    %{
      "content-security-policy" => Enum.map_join(allowed, ";", &format/1)
    }
  end

  defp format({perm, sources}) do
    src_str = Enum.map_join(sources, " ", &format_source/1)

    Enum.join([perm, src_str], " ")
  end

  defp format_source({:url, permission}) do
    permission
  end

  defp format_source(source), do: "'#{source}'"
end
