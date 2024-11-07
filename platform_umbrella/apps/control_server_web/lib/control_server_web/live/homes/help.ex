defmodule ControlServerWeb.Live.Help do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.URLs

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, :help)
     |> assign(:page_title, "Get Help")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.flex column class="items-center justify-center h-full text-gray-darkest dark:text-gray-lighter">
      <.icon name={:question_mark_circle} class="size-60 text-primary opacity-35" />
      <.h2>Need Some Help?</.h2>

      <div class="max-w-lg">
        <p class="mb-8">
          Batteries Included is still in beta, so we'd love your feedback! Feel free to check out the docs, open an issue on GitHub, or just drop into Slack to say hey.
        </p>

        <div class="flex gap-4">
          <.a
            variant="bordered-lg"
            icon={:book_open}
            href={docs_url()}
            target="_blank"
            class="opacity-35 hover:opacity-100"
          >
            Docs
          </.a>
          <.a variant="bordered-lg" icon={:github} href={github_url()} target="_blank">GitHub</.a>
          <.a variant="bordered-lg" icon={:slack} href={slack_url()} target="_blank">Slack</.a>
        </div>
      </div>
      <.flex class="mt-auto items-center justify-around text-gray">
        <span><%= CommonCore.Version.version() %></span>
        <span><%= CommonCore.Version.hash() %></span>
      </.flex>
    </.flex>
    """
  end
end
