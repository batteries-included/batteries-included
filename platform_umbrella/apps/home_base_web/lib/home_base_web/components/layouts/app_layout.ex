defmodule HomeBaseWeb.Layouts.AppLayout do
  @moduledoc false
  use HomeBaseWeb, :html

  def app(assigns) do
    ~H"""
    <.flex column>
      <.flex class="relative shadow-sm header-gradient items-center px-8">
        <.logo variant="full" class="my-3" />
        <div class="flex-grow">
          <!-- Spacer -->
        </div>
        <.menu current_user={@current_user} />
      </.flex>

      <main role="main">
        <.flash kind={:info} title="Success!" flash={@flash} />
        <.flash kind={:error} title="Error!" flash={@flash} />
        <.flash
          id="disconnected"
          kind={:error}
          title="We can't find the internet"
          close={false}
          autoshow={false}
          phx-disconnected={show_flash("#disconnected")}
          phx-connected={hide_flash("#disconnected")}
        >
          Attempting to reconnect
          <.icon name={:arrow_path} class="inline w-3 h-3 ml-1 animate-spin" />
        </.flash>

        <%= @inner_content %>
      </main>
    </.flex>
    """
  end

  defp menu(assigns) do
    ~H"""
    <nav class="order-last">
      <ul class="flex gap-8">
        <%= for item <- items(@current_user) do %>
          <li class="flex items-center">
            <.a href={item.url} variant="styled" method={Map.get(item, :method, nil)}>
              <%= item.title %>
            </.a>
          </li>
        <% end %>
      </ul>
    </nav>
    """
  end

  defp items(%{} = _user) do
    [
      %{title: "Dashboard", url: ~p"/"},
      %{title: "Installations", url: ~p"/installations"},
      %{title: "Profile", url: ~p"/users/settings"},
      %{title: "Log out", url: ~p"/users/log_out", method: "delete"}
    ]
  end

  defp items(_) do
    [
      %{title: "Register", url: ~p"/users/register"},
      %{title: "Log in", url: ~p"/users/log_in"}
    ]
  end
end
