defmodule CommonUIWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use CommonUIWeb, :live_component
      use CommonUIWeb, :component

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)
  def global_prefixes, do: ~w(x- phx- aria- data-)

  def component do
    quote do
      use Phoenix.Component,
        global_prefixes: CommonUIWeb.global_prefixes()

      alias Phoenix.LiveView.JS
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent,
        global_prefixes: CommonUIWeb.global_prefixes()

      alias Phoenix.LiveView.JS
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
