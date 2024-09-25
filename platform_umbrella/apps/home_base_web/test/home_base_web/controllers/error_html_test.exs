defmodule HomeBaseWeb.ErrorHTMLTest do
  use HomeBaseWeb.ConnCase, async: true

  # Bring render_to_string/3 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(HomeBaseWeb.ErrorHTML, "404", "html", []) =~ "Oops!"
  end

  test "renders 500.html" do
    assert render_to_string(HomeBaseWeb.ErrorHTML, "500", "html", []) =~ "Oh no!"
  end
end
