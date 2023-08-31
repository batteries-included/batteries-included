defmodule PC do
  @moduledoc """
  Petal Components.

      <PC.button label="Go" />
  """
  defdelegate accordion(assigns), to: PetalComponents.Accordion
  defdelegate alert(assigns), to: PetalComponents.Alert
  defdelegate avatar(assigns), to: PetalComponents.Avatar
  defdelegate badge(assigns), to: PetalComponents.Badge
  defdelegate breadcrumbs(assigns), to: PetalComponents.Breadcrumbs
  defdelegate button(assigns), to: PetalComponents.Button
  defdelegate card(assigns), to: PetalComponents.Card
  defdelegate container(assigns), to: PetalComponents.Container
  defdelegate dropdown(assigns), to: PetalComponents.Dropdown
  defdelegate field(assigns), to: PetalComponents.Field
  defdelegate icon(assigns), to: PetalComponents.Icon
  defdelegate input(assigns), to: PetalComponents.Input
  defdelegate a(assigns), to: PetalComponents.Link
  defdelegate spinner(assigns), to: PetalComponents.Loading
  defdelegate modal(assigns), to: PetalComponents.Modal
  defdelegate pagination(assigns), to: PetalComponents.Pagination
  defdelegate progress(assigns), to: PetalComponents.Progress
  defdelegate rating(assigns), to: PetalComponents.Rating
  defdelegate slide_over(assigns), to: PetalComponents.SlideOver
  defdelegate table(assigns), to: PetalComponents.Table
  defdelegate td(assigns), to: PetalComponents.Table
  defdelegate tr(assigns), to: PetalComponents.Table
  defdelegate th(assigns), to: PetalComponents.Table
  defdelegate tabs(assigns), to: PetalComponents.Tabs
  defdelegate h1(assigns), to: PetalComponents.Typography
  defdelegate h2(assigns), to: PetalComponents.Typography
  defdelegate h3(assigns), to: PetalComponents.Typography
  defdelegate h4(assigns), to: PetalComponents.Typography
  defdelegate h5(assigns), to: PetalComponents.Typography
  defdelegate p(assigns), to: PetalComponents.Typography
  defdelegate prose(assigns), to: PetalComponents.Typography
  defdelegate ol(assigns), to: PetalComponents.Typography
  defdelegate ul(assigns), to: PetalComponents.Typography
end
