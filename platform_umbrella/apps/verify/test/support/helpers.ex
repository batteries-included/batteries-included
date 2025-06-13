defmodule Verify.TestCase.Helpers do
  @moduledoc false

  import ExUnit.Assertions
  import Wallaby.Browser

  alias Verify.PathHelper
  alias Wallaby.Query

  @backspaces Enum.map(0..100, fn _ -> :backspace end)
  @deletes Enum.map(0..100, fn _ -> :delete end)

  # Adapted from Wallaby.Feature.feature/3
  @doc """
  `verify` wraps ExUnit.test so that test failures take a screenshot and runs `bi rage`.

  The context will automatically be populated with:
  - A wallaby session set to the correct URL: `session`
  - A module specific temp directory. This directory is automatically uploaded on failure in CI: `tmp_dir`
  - The tested version: `tested_version`
  - The URL of the control server: `control_url`
  - The name/pid of the BatteryInstallWorker: `battery_install_worker`
  - The path to the kube config file for the cluster: `kube_config_path`
  """
  defmacro verify(message, context \\ quote(do: _), contents) do
    %{module: mod, file: file, line: line} = __CALLER__

    contents =
      quote do
        try do
          unquote(contents)
          :ok
        rescue
          e ->
            out = unquote(__MODULE__).rage_output_for_test(unquote(mod), unquote(message))

            Wallaby.Feature.Utils.take_screenshots_for_sessions(self(), unquote(message))
            # taking a screenshot writes the paths without a final newline so add it here
            IO.write("\n")
            Verify.KindInstallWorker.rage(unquote(mod), out)

            reraise(e, __STACKTRACE__)
        end
      end

    context = Macro.escape(context)
    contents = Macro.escape(contents, unquote: true)

    quote bind_quoted: [
            mod: mod,
            file: file,
            line: line,
            context: context,
            contents: contents,
            message: message
          ] do
      name = ExUnit.Case.register_test(mod, file, line, :verification, message, [:verify])

      def unquote(name)(unquote(context)), do: unquote(contents)
    end
  end

  @spec get_tmp_dir(module()) :: String.t()
  def get_tmp_dir(mod) do
    Path.join([PathHelper.tmp_dir!(), "bi-int-test", Atom.to_string(mod)])
  end

  @spec rage_output_for_test(module(), binary()) :: String.t()
  def rage_output_for_test(mod, message) do
    tmp_dir = get_tmp_dir(mod)
    name = String.replace(message, " ", "_")

    time = :second |> :erlang.system_time() |> to_string()
    Path.join([tmp_dir, "#{time}_#{name}.json"])
  end

  def table_row(opts \\ []), do: Query.css("table tbody tr", opts)
  def h3(text, opts \\ []), do: Query.css("h3", Keyword.put(opts, :text, text))

  def assert_pod(session, name_fragment) do
    session
    |> visit("/kube/pods")
    |> assert_has(table_row(minimum: 6))
    |> fill_in(Query.text_field("filter_value"), with: name_fragment)
    |> assert_has(table_row(text: name_fragment, count: 1))
  end

  def assert_pod_running(session, name_fragment), do: assert_pods_running(session, [name_fragment])

  def assert_pods_running(session, name_fragments) do
    path = current_path(session)

    session
    |> visit("/kube/pods")
    |> assert_has(table_row(minimum: 6))

    Enum.each(name_fragments, fn frag ->
      session
      |> fill_in(Query.text_field("filter_value"), with: frag)
      |> assert_has(table_row(text: "Running", count: 1))
    end)

    # "reset" the session back to the original location
    visit(session, path)
  end

  def assert_pods_in_deployment_running(session, namespace, deployment) do
    deployment_url = "/kube/deployment/#{namespace}/#{deployment}/show"

    # make sure the deployment page is available
    {:ok, _} =
      :wallaby
      |> Application.get_env(:base_url)
      |> Path.join(deployment_url)
      |> build_retryable_get()
      |> retry()

    session =
      session
      |> visit(deployment_url)
      # check we're on the pods page for the deployment
      |> assert_has(h3(deployment))

    # get all of the pod rows
    pods = all(session, Query.css("table#pods_table"))

    # make sure all pods are Running
    assert_has(session, table_row(text: "Running", count: length(pods)))

    session
  end

  def create_pg_cluster(session, cluster_name) do
    session
    # create new cluster
    |> visit("/postgres/new")
    |> assert_has(h3("New Postgres Cluster"))
    |> fill_in_name("cluster[name]", cluster_name)
    |> click(Query.button("Save"))
  end

  @doc """
  fill in the name field where we are auto-populating a random name
  based on Ecto validation. The normal `Wallaby.Browser.fill_in/3`
  triggers the name to be re-generated between clearing out the field
  and filling in the new value so that we get e.g. `a-b-cint-test-123`
  or `int-test-123a-b-c`
  """
  def fill_in_name(session, field_name, text_to_fill) do
    find(session, Query.text_field(field_name), fn e ->
      Wallaby.Element.send_keys(e, @backspaces ++ @deletes ++ [text_to_fill])
    end)
  end

  def assert_path(session, %Regex{} = match) do
    path = current_path(session)
    assert path =~ match

    session
  end

  def assert_path(session, match) do
    path = current_path(session)
    assert path === match

    session
  end

  def trigger_k8s_deploy(session) do
    session
    |> visit("/magic")
    |> click(Query.button("Start Deploy"))
    |> sleep(1_000)
  end

  @doc """
  Clicks a link to an "external" site first checking that site is available
  Then clicking the element returned by the passed in query
  And finally focusing on the newly opened window/tab
  """
  def click_external(session, query) do
    # get the URL that we will be visiting
    url = attr(session, query, "href")
    assert url != nil

    # retry until success or timeout
    {:ok, _} = url |> build_retryable_get() |> retry()

    initial_window_handle = window_handle(session)

    # click
    session = click(session, query)
    new_handle = session |> window_handles() |> Enum.find(fn handle -> handle != initial_window_handle end)
    focus_window(session, new_handle)
  end

  def visit_running_service(session, text \\ "Running Service") do
    click_external(session, Query.css("a", text: text))
  end

  def sleep(session, timeout) do
    Process.sleep(timeout)
    session
  end

  defp build_retryable_get(url) do
    client = Tesla.client([{Tesla.Middleware.FollowRedirects, max_redirects: 3}])

    fn ->
      case Tesla.get(client, url) do
        {:ok, %{status: 200} = resp} ->
          {:ok, resp}

        # retry after sleep on non-200 resp
        {_, resp} ->
          Process.sleep(500)
          {:error, resp}
      end
    end
  end
end
