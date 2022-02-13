defmodule CommonUI do
  @moduledoc """
  Documentation for `CommonUI`.
  """

  use Phoenix.Component

  def labeled_definition(assigns) do
    ~H"""
    <div class="px-4 py-5 bg-white shadow rounded-lg overflow-hidden sm:p-6">
      <dt class="text-sm font-medium text-gray-500 truncate">
        <%= @title %>
      </dt>
      <dd class="mt-1 text-3xl font-semibold text-gray-900">
        <%= @contents %>
      </dd>
    </div>
    """
  end
end
