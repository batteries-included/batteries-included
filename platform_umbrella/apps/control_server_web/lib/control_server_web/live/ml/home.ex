defmodule ControlServerWeb.Live.MLHome do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>ML Home</.title>
      </:title>
      <:left_menu>
        <.ml_menu active="home" />
      </:left_menu>
      <.body_section></.body_section>
    </.layout>
    """
  end
end
