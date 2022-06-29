defmodule ControlServerWeb.Live.UserIndex do
  use ControlServerWeb, :live_view
  import ControlServerWeb.LeftMenuLayout
  import CommonUI.Table
  alias ControlServer.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :users, list_users())}
  end

  def list_users do
    Accounts.list_users()
  end

  def new_user_url, do: Routes.user_new_path(ControlServerWeb.Endpoint, :index)

  def show_user_url(user), do: Routes.user_show_path(ControlServerWeb.Endpoint, :index, user.id)

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Users</.title>
      </:title>
      <:left_menu>
        <.security_menu active="users" />
      </:left_menu>
      <.section_title>
        Control Server Users
      </.section_title>
      <.body_section>
        <.table>
          <.thead>
            <.tr>
              <.th>Email</.th>
              <.th>Join Date</.th>
              <.th>Action</.th>
            </.tr>
          </.thead>
          <.tbody id="users">
            <%= for user <- @users do %>
              <.tr id={"user-#{user.id}"}>
                <.td><%= user.email %></.td>
                <.td>
                  <%= user.inserted_at %>
                </.td>
                <.td>
                  <.link to={show_user_url(user)}>Show User</.link>
                </.td>
              </.tr>
            <% end %>
          </.tbody>
        </.table>

        <div class="ml-8 mt-15">
          <.button type="primary" variant="shadow" to={new_user_url()} link_type="live_patch">
            New User
          </.button>
        </div>
      </.body_section>
    </.layout>
    """
  end
end
