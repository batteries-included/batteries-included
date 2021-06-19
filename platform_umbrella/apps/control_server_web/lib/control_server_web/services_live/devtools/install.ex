defmodule ControlServerWeb.ServicesLive.DevtoolsInstall do
  use Surface.LiveView

  alias CommonUI.Progress
  alias CommonUI.Progress.Step
  alias ControlServerWeb.Live.Layout
  alias ControlServerWeb.ServicesLive.DevtoolsStepZero

  require Logger

  data step, :integer, default: 0
  data scm_provider, :atom, default: :github

  def handle_event("progress:change" = e_name, %{"payload" => index} = e, socket) do
    {int_val, ""} = Integer.parse(index)
    Logger.debug("Got #{e_name}  payload = #{inspect(e)} for socket = #{inspect(socket)}")

    {:noreply, assign(socket, :step, int_val)}
  end

  def render(assigns) do
    ~F"""
    <Layout>
      <div class="max-w-4xl mx-auto">
        <div class="flex flex-col overflow-hidden bg-white divide-y divide-gray-200 rounded-lg shadow">
          <DevtoolsStepZero />
          <div class="px-4 py-5 sm:p-6">
            <Progress>
              <Step name="Github/Gitlab" index={0} is_done={@step >= 0} change="progress:change" />
              <Step name="Details" index={1} is_done={@step >= 1} change="progress:change" />
              <Step name="Preview" index={2} is_done={@step >= 2} change="progress:change" />
            </Progress>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
