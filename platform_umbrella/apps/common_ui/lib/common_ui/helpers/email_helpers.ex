defmodule CommonUI.EmailHelpers do
  @moduledoc ~S'''
  This module injects `render/1` into the using module,
  which renders email templates into the layouts defined
  in `components/email.ex` and returns a ready-to-send
  Swoosh email struct.

  ## Example

      defmodule HomeBaseWeb.FoobarEmail do
        use CommonUI.EmailHelpers, endpoint: HomeBaseWeb.Endpoint

        def subject, do: "Greetings"

        def text(assigns) do
          ~H"""
          Hello <%= @name %>
          """
        end

        def html(assigns) do
          ~H"""
          <p>Hello <%= @name %></p>
          """
        end
      end

  ## Sending

      %{to: "jane@doe.com", name: "Jane"}
      |> HomeBaseWeb.FoobarEmail.render()
      |> HomeBase.Mailer.deliver()

  ## Options

    * `:endpoint` - The app endpoint used when constructing
      URLs. This is required.

    * `:from` - The default from address to use when sending
      an email. This can also be defined in the assigns to
      override the default address.
    
    * `:street_address` - The street address that gets rendered
      into the email footer. This helps to prevent the email from
      being marked as spam.

    * `:home_url` - The URL used when constructing links to
      the marketing site and image paths hosted there (such as
      the logo). This is required.

  ## Functions

    * `subject/1` - Use this function to define the email
      subject. No subject will be set if this is not defined.
      Receives the Swoosh.Email struct as the first argument.

    * `text/1` - Use this function to define the plain text
      template. Receives the assigns as the first argument.
      
    * `html/1` - Use this function to define the HTML HEEx
      template. Receives the assigns as the first argument.

  '''

  alias CommonUI.Components.Email

  defmacro __using__(opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    from = Keyword.get(opts, :from)
    street_address = Keyword.get(opts, :street_address)
    home_url = Keyword.fetch!(opts, :home_url)

    quote do
      import CommonUI.EmailHelpers

      def render(assigns) do
        functions = __MODULE__.__info__(:functions)

        email =
          [assigns: assigns]
          |> Swoosh.Email.new()
          |> Swoosh.Email.to(Map.get(assigns, :to))
          |> Swoosh.Email.from(Map.get(assigns, :from, unquote(from)))
          |> Swoosh.Email.assign(:street_address, unquote(street_address))
          |> Swoosh.Email.assign(:static_url, unquote(endpoint).static_url())
          |> Swoosh.Email.assign(:home_url, unquote(home_url))

        email = if Keyword.has_key?(functions, :subject), do: assign_subject(email, __MODULE__), else: email
        email = if Keyword.has_key?(functions, :text), do: render_text(email, __MODULE__), else: email
        email = if Keyword.has_key?(functions, :html), do: render_html(email, __MODULE__), else: email

        email
      end
    end
  end

  def assign_subject(email, module) do
    subject = module.subject(email)

    email
    |> Swoosh.Email.subject(subject)
    |> Swoosh.Email.assign(:subject, subject)
  end

  def render_text(email, module) do
    assigns = Map.put_new(email.assigns, :layout, {Email, "email_text_layout"})
    text = Phoenix.Template.render_to_string(module, "text", "text", assigns)

    Swoosh.Email.text_body(email, text)
  end

  def render_html(email, module) do
    assigns = Map.put_new(email.assigns, :layout, {Email, "email_html_layout"})

    html =
      module
      |> Phoenix.Template.render_to_string("html", "html", assigns)
      |> Premailex.to_inline_css()

    Swoosh.Email.html_body(email, html)
  end
end
