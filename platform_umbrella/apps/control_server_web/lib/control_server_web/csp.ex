defmodule ControlServerWeb.CSP do
  @default_allowed %{
    "script-src" => ["self", "unsafe-eval", "unsafe-inline"],
    "default-src" => ["self", {:url, "https://rsms.me"}, "unsafe-inline"],
    "img-src" => ["self", {:url, "data:"}, {:url, "https://images.unsplash.com"}],
    "font-src" => ["self", {:url, "data:"}, {:url, "https://rsms.me"}],
    "frame-src" => [
      "self",
      {:url, "localhost:8081"},
      {:url, "localhost:4000"},
      {:url, "anton2:8081"},
      {:url, "anton2:4000"}
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
