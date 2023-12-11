defmodule ControlServerWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ControlServerWeb, :controller
      use ControlServerWeb, :html

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
        namespace: ControlServerWeb,
        formats: [:html, :json],
        layouts: [html: ControlServerWeb.Layouts]

      import ControlServerWeb.Gettext
      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view(opts \\ []) do
    layout = Keyword.get(opts, :layout, :app)
    global_prefixes = Keyword.get(opts, :global_prefixes, ["x-"])

    quote do
      use Phoenix.LiveView,
        global_prefixes: unquote(global_prefixes),
        layout: {ControlServerWeb.Layouts, unquote(layout)}

      import Phoenix.Component, except: [link: 1]

      on_mount {ControlServerWeb.InstalledBatteriesHook, :installed_batteries}

      unquote(html_helpers())
    end
  end

  def live_component(opts \\ []) do
    global_prefixes = Keyword.get(opts, :global_prefixes, ["x-"])

    quote do
      use Phoenix.LiveComponent, global_prefixes: unquote(global_prefixes)

      import Phoenix.Component, except: [link: 1]

      unquote(html_helpers())
    end
  end

  def html(opts \\ []) do
    global_prefixes = Keyword.get(opts, :global_prefixes, ["x-"])

    quote do
      use Phoenix.Component, global_prefixes: unquote(global_prefixes)

      import Phoenix.Component, except: [link: 1]

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
      # import ControlServerWeb.CoreComponents
      use CommonUI
      use ControlServerWeb.Common

      import ControlServerWeb.Gettext
      import Phoenix.HTML

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ControlServerWeb.Endpoint,
        router: ControlServerWeb.Router,
        statics: ControlServerWeb.static_paths()
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
