defmodule CommonUI.EmailHelpersTest do
  use ExUnit.Case

  use CommonUI.EmailHelpers,
    endpoint: CommonUIWeb.Endpoint,
    from: {"Test", "test@test.com"},
    street_address: "123 Easy St, New York, NY 10001",
    marketing_url: "http://127.0.0.1:4321"

  import Phoenix.Component

  def subject(_email), do: "This is a subject"

  def text(assigns) do
    ~s"""
    *Hey #{assigns.name}*
    """
  end

  def html(assigns) do
    ~H"""
    <p>Hey {@name}</p>
    """
  end

  test "render/1" do
    email = __MODULE__.render(%{name: "Jane"})

    floki_doc = Floki.parse_document!(email.html_body)
    assert email.from == {"Test", "test@test.com"}
    assert email.text_body =~ "*Hey Jane*"
    assert email.text_body =~ "123 Easy St"
    assert floki_doc |> Floki.find("title") |> Floki.text() == "This is a subject"
    assert floki_doc |> Floki.find("p") |> Floki.text() == "Hey Jane"
    assert ["http://127.0.0.1:4321"] = Floki.attribute(floki_doc, ".logo a", "href")
    assert ["http://127.0.0.1:4321/images/emails/logo.png"] = Floki.attribute(floki_doc, ".logo a img", "src")
    assert ["font-family: Helvetica" <> _] = Floki.attribute(floki_doc, "p", "style")
  end
end
