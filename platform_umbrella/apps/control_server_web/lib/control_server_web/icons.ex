defmodule ControlServerWeb.Icons do
  @moduledoc """
  Module to make svg icons available.
  """
  use Phoenix.HTML
  alias ControlServerWeb.Router.Helpers, as: Routes

  def icon_tag(conn, name, opts \\ []) do
    classes = Keyword.get(opts, :class, "") <> " icon"

    content_tag(:svg, class: classes) do
      tag(:use, "xlink:href": Routes.static_path(conn, "/images/bootstrap-icons.svg#" <> name))
    end
  end
end
