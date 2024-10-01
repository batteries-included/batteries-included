defmodule HomeBaseWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use HomeBaseWeb, :controller
      use HomeBaseWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        namespace: HomeBaseWeb,
        formats: [:html, :json]

      use Gettext, backend: CommonUI.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def email(opts \\ []) do
    opts =
      Keyword.merge(
        [
          endpoint: HomeBaseWeb.Endpoint,
          from: {"Batteries Included", "system@batteriesincl.com"},
          street_address: "Batteries Included, 8 The Green, Ste. B, Dover, DE 19901",
          home_url: Application.fetch_env!(:home_base_web, :home_url)
        ],
        opts
      )

    quote do
      use Phoenix.Component
      use CommonUI.EmailHelpers, unquote(opts)

      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      # Core UI components and translation
      use CommonUI
      use Gettext, backend: CommonUI.Gettext

      import Phoenix.HTML
      import Phoenix.HTML.Form

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HomeBaseWeb.Endpoint,
        router: HomeBaseWeb.Router,
        statics: HomeBaseWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end
end
