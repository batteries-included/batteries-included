defmodule HomeBaseWeb.HelpLive do
  @moduledoc false
  use HomeBaseWeb, :live_view

  import CommonCore.URLs

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, :help)
     |> assign(:page_title, "Get Help")}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-full">
      <.icon name={:question_mark_circle} class="size-60 mx-auto text-primary opacity-15" />
      <.h2 class="mb-8">Need Some Help?</.h2>

      <div class="max-w-lg">
        <p class="mb-8">
          Batteries Included is still in beta, so we'd love your feedback! Feel free to check out the docs, open an issue on GitHub, or just drop into Slack to say hey.
        </p>

        <div class="flex gap-4">
          <.a variant="bordered-lg" icon={:book_open} href={docs_url()} target="_blank">Docs</.a>
          <.a variant="bordered-lg" icon={:github} href={github_url()} target="_blank">GitHub</.a>
          <.a variant="bordered-lg" icon={:slack} href={slack_url()} target="_blank">Slack</.a>
        </div>
      </div>
    </div>
    """
  end
end
