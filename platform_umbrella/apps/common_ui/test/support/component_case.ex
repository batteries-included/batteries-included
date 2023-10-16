defmodule ComponentCase do
  @moduledoc ~S|
  Use with your component tests. Example:

      defmodule CommonUI.BrandTest do
        use ComponentCase
        import CommonUI.Brand

        test "it renders the logo correctly" do
          assigns = %{}

          html =
            rendered_to_string(~H"""
            <.logo class="some-class" />
            """)

          assert html =~ "Batteries"
          assert html =~ "some-class"
        end
      end
  |

  use ExUnit.CaseTemplate

  setup do
    # This will run before each test that uses this case
    :ok
  end

  using do
    quote do
      import Phoenix.Component
      import Phoenix.LiveViewTest
      import Plug.HTML, only: [html_escape: 1]
    end
  end
end
