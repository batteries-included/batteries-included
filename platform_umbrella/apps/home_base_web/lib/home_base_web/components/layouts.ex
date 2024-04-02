defmodule HomeBaseWeb.Layouts do
  @moduledoc false
  use HomeBaseWeb, :html

  embed_templates "layouts/*"
  defdelegate app(assigns), to: HomeBaseWeb.Layouts.AppLayout
end
