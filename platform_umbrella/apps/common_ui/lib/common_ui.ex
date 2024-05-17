defmodule CommonUI do
  @moduledoc """
  CommonUI keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def component do
    quote do
      use Phoenix.Component

      alias Phoenix.LiveView.JS
    end
  end

  @doc """
  When used, dispatch to the appropriate macro.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(_) do
    quote do
      import CommonUI.Components.Alert
      import CommonUI.Components.Badge
      import CommonUI.Components.Button
      import CommonUI.Components.ClickFlip
      import CommonUI.Components.Container
      import CommonUI.Components.DataList
      import CommonUI.Components.DatetimeDisplay
      import CommonUI.Components.Dropdown
      import CommonUI.Components.Email
      import CommonUI.Components.FlashGroup
      import CommonUI.Components.Form
      import CommonUI.Components.Icon
      import CommonUI.Components.Input
      import CommonUI.Components.Link
      import CommonUI.Components.Loader
      import CommonUI.Components.Logo
      import CommonUI.Components.Modal
      import CommonUI.Components.MutliSelect
      import CommonUI.Components.Panel
      import CommonUI.Components.Progress
      import CommonUI.Components.TabBar
      import CommonUI.Components.Table
      import CommonUI.Components.Tooltip
      import CommonUI.Components.Typography
      import CommonUI.Components.VerticalSteps
      import CommonUI.Components.Video
      import CommonUI.TextHelpers
    end
  end
end
