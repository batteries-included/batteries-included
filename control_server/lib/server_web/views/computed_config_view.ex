defmodule ServerWeb.ComputedConfigView do
  use ServerWeb, :view
  alias ServerWeb.ComputedConfigView

  def render("show.json", %{computed_config: computed_config}) do
    %{data: render_one(computed_config, ComputedConfigView, "computed_config.json")}
  end

  def render("computed_config.json", %{computed_config: computed_config}) do
    %{path: computed_config.path, content: computed_config.content}
  end
end
