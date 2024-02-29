defmodule Storybook.Colors do
  @moduledoc false
  use PhoenixStorybook.Story, :page

  def navigation do
    [
      # TODO: Submit PR to phoenix_storybook allowing subnavigation without icons
      {:primary, "Primary", {:fa, ""}},
      {:secondary, "Secondary", {:fa, ""}},
      {:success, "Success", {:fa, ""}},
      {:warning, "Warning", {:fa, ""}},
      {:error, "Error", {:fa, ""}},
      {:gray, "Gray", {:fa, ""}}
    ]
  end

  def color(assigns) do
    ~H"""
    <div class="flex items-center mb-4">
      <div class={[
        "flex flex-col items-center justify-center rounded w-40 h-20 mr-5 font-mono",
        @class
      ]}>
        <span class="text-base mb-1"><%= @hex %></span>
        <span class="text-xs opacity-75"><%= @name %></span>
      </div>

      <div :if={assigns[:description]}><%= @description %></div>
    </div>
    """
  end

  def render(%{tab: :primary} = assigns) do
    ~H"""
    <div class="psb-colors-page">
      <.color
        hex="#FFA8CB"
        name="primary-light"
        class="bg-primary-light text-gray-darkest"
        description="Used for light borders"
      />
      <.color
        hex="#FC408B"
        name="primary"
        class="bg-primary text-white"
        description="Used for brand, primary buttons"
      />
      <.color
        hex="#DE2E74"
        name="primary-dark"
        class="bg-primary-dark text-white"
        description="Used for primary button hover"
      />
    </div>
    """
  end

  def render(%{tab: :secondary} = assigns) do
    ~H"""
    <div class="psb-colors-page">
      <.color hex="#DEFAF8" name="secondary-light" class="bg-secondary-light text-gray-darkest" />
      <.color hex="#97EFE9" name="secondary" class="bg-secondary text-gray-darkest" />
      <.color hex="#36E0D4" name="secondary-dark" class="bg-secondary-dark text-gray-darkest" />
    </div>
    """
  end

  def render(%{tab: :success} = assigns) do
    ~H"""
    <div class="psb-colors-page">
      <.color hex="#79E2BB" name="success-light" class="bg-success-light text-white" />
      <.color hex="#36D399" name="success" class="bg-success text-white" />
      <.color hex="#26AB7A" name="success-dark" class="bg-success-dark text-white" />
    </div>
    """
  end

  def render(%{tab: :warning} = assigns) do
    ~H"""
    <div class="psb-colors-page">
      <.color hex="#FBDBA2" name="warning-light" class="bg-warning-light text-gray-darkest" />
      <.color hex="#F6AE2D" name="warning" class="bg-warning text-white" />
      <.color hex="#E1940A" name="warning-dark" class="bg-warning-dark text-white" />
    </div>
    """
  end

  def render(%{tab: :error} = assigns) do
    ~H"""
    <div class="psb-colors-page">
      <.color hex="#EA7B88" name="error-light" class="bg-error-light text-white" />
      <.color hex="#D42F40" name="error" class="bg-error text-white" />
      <.color hex="#831B25" name="error-dark" class="bg-error-dark text-white" />
    </div>
    """
  end

  def render(%{tab: :gray} = assigns) do
    ~H"""
    <div class="psb-colors-page">
      <.color
        hex="#FAFAFA"
        name="gray-lightest"
        class="bg-gray-lightest text-gray-dark"
        description="Used for table rows, panel backgrounds"
      />
      <.color
        hex="#DADADA"
        name="gray-lighter"
        class="bg-gray-lighter text-gray-dark"
        description="Used for light borders, input backgrounds"
      />
      <.color
        hex="#999A9F"
        name="gray-light"
        class="bg-gray-light text-white"
        description="Used for disabled link text"
      />
      <.color
        hex="#7F7F7F"
        name="gray"
        class="bg-gray text-white"
        description="Used for disabled button text, input placeholders"
      />
      <.color
        hex="#545155"
        name="gray-dark"
        class="bg-gray-dark text-white"
        description="Used for primary text"
      />
      <.color
        hex="#38383A"
        name="gray-darker"
        class="bg-gray-darker text-white"
        description="Used for dark button hover"
      />
      <.color
        hex="#1C1C1E"
        name="gray-darkest"
        class="bg-gray-darkest text-white"
        description="Used for dark buttons, input labels"
      />
    </div>
    """
  end
end
