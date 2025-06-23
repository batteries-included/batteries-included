defmodule Verify.TestCase.Helpers do
  @moduledoc """
  Contains test helpers (i.e. assertions and repeated actions)
  """

  import ExUnit.Assertions
  import Wallaby.Browser, except: [visit: 2]

  alias Wallaby.Query

  @backspaces Enum.map(0..100, fn _ -> :backspace end)
  @deletes Enum.map(0..100, fn _ -> :delete end)

  @container_panel Query.css("#containers_panel-containers")
  @port_panel Query.css("#ports_panel")

  @keycloak_realm_path "/keycloak/realms"

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

    session =
      session
      |> visit("/kube/pods")
      |> assert_has(table_row(minimum: 6))

    session =
      Enum.reduce(name_fragments, session, fn frag, acc ->
        acc
        |> fill_in(Query.text_field("filter_value"), with: frag)
        |> sleep(100)
        |> assert_has(table_row(text: "Running", count: 1))
      end)

    # "reset" the session back to the original location
    visit(session, path)
  end

  def assert_pods_in_sts_running(session, namespace, sts) do
    assert_workflow_pods_running(session, sts, "/kube/stateful_set/#{namespace}/#{sts}/show")
  end

  def assert_pods_in_deployment_running(session, namespace, deployment) do
    assert_workflow_pods_running(session, deployment, "/kube/deployment/#{namespace}/#{deployment}/show")
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

  def assert_confirmation(session, fun, search_text) do
    msg = accept_confirm(session, fun)

    assert String.contains?(msg, search_text)
    session
  end

  def trigger_k8s_deploy(session) do
    path = current_path(session)

    session
    |> visit("/magic")
    |> click(Query.button("Start Deploy"))
    |> sleep(500)
    |> visit(path)
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

  defp assert_workflow_pods_running(session, workload, path) do
    # make sure the page is available
    {:ok, _} =
      :wallaby
      |> Application.get_env(:base_url)
      |> Path.join(path)
      |> build_retryable_get()
      |> retry()

    session =
      session
      |> visit(path)
      # check we're on the pods page for the deployment
      |> assert_has(h3(workload))

    # get all of the pod rows
    pods = all(session, Query.css("table#pods_table"))

    session =
      session
      # make sure all pods are Running
      |> assert_has(table_row(text: "Running", count: length(pods)))
      # trigger a deploy
      |> trigger_k8s_deploy()
      # and double check all pods are running
      |> visit(path)
      |> assert_has(table_row(text: "Running", count: length(pods)))

    session
  end

  def create_traditional_service(session, image, service_name) do
    session
    # create service
    |> visit("/traditional_services/new")
    |> assert_has(h3("New Traditional Service"))
    |> fill_in_name("service[name]", service_name)
    # add container
    |> find(@container_panel, fn e -> click(e, Query.button("Add Container")) end)
    |> fill_in(Query.text_field("container[name]"), with: "workload")
    |> fill_in(Query.text_field("container[image]"), with: image)
    |> click(Query.css(~s/#container-form-modal-modal-container button[type="submit"]/))
    # make sure the modal is gone
    |> sleep(100)
    |> immediately_refute_has(Query.css("#container-form-modal"))
    # add port
    |> find(@port_panel, fn e -> click(e, Query.button("Add Port")) end)
    |> fill_in(Query.text_field("port[name]"), with: service_name)
    |> fill_in(Query.text_field("port[number]"), with: "80")
    |> click(Query.css(~s/#port-form-modal-modal-container button[type="submit"]/))
    # make sure the modal is gone
    |> sleep(100)
    |> immediately_refute_has(Query.css("#port-form-modal"))
    # save service
    |> click(Query.button("Save Traditional Service"))
  end

  def immediately_refute_has(parent, query) do
    case execute_query_without_retry(parent, query) do
      {:error, :invalid_selector} ->
        raise Wallaby.QueryError,
              Query.ErrorMessage.message(query, :invalid_selector)

      {:error, _not_found} ->
        parent

      # no results means not found
      {:ok, %{result: []}} ->
        parent

      {:ok, query} ->
        raise Wallaby.ExpectationNotMetError,
              Query.ErrorMessage.message(query, :found)
    end
  end

  defp execute_query_without_retry(%{driver: driver} = parent, query) do
    with {:ok, query} <- Query.validate(query),
         compiled_query = Query.compile(query),
         {:ok, elements} <- driver.find_elements(parent, compiled_query) do
      {:ok, %{query | result: elements}}
    end
  rescue
    Wallaby.StaleReferenceError ->
      {:error, :stale_reference}
  end

  def check_keycloak_running(session) do
    session
    |> assert_pods_in_sts_running("battery-core", "keycloak")
    |> visit(@keycloak_realm_path)
    # wait for the admin realm
    |> assert_has(table_row(minimum: 1))
    |> trigger_k8s_deploy()
    |> visit(@keycloak_realm_path)
    # wait for the default realm
    |> assert_has(table_row(minimum: 2))
  end

  # need to already be on realm page. see `navigate_to_keycloak_realm/2`
  def login_keycloak(session, username, password) do
    session
    |> assert_has(Query.css("h1", text: "Sign in to your account"))
    |> fill_in(Query.text_field("username"), with: username)
    |> fill_in(Query.text_field("password"), with: password)
    |> click(Query.button("Sign In"))
  end

  def navigate_to_keycloak_realm(session, name) do
    session
    # from the net_sec page
    |> visit("/net_sec")
    |> assert_has(h3("Realms"))
    # go to the admin realm view page
    |> click(Query.css("td", text: name))
    |> assert_has(h3(name))
  end

  def create_keycloak_user(session, email, user, password, first, last) do
    session =
      session
      # create the new user
      |> click(Query.button("New User"))
      |> assert_has(Query.css("h2", text: "New User"))
      |> fill_in(Query.text_field("user_representation[email]"), with: email)
      |> fill_in(Query.text_field("user_representation[username]"), with: user)
      |> click(Query.button("Create User"))
      |> assert_has(Query.css("p", text: "User has been created!"))

    # get the temp password
    temp_password = text(session, Query.css("pre"))

    session
    # exit the modal
    |> click(Query.css("#temp-password-modal-container button"))
    # login to keycloak
    |> click(Query.link("Admin Console"))
    |> last_tab()
    |> login_keycloak(user, temp_password)
    |> assert_has(Query.css("h1", text: "Update password"))
    |> fill_in(Query.text_field("password-new"), with: password)
    |> fill_in(Query.text_field("password-confirm"), with: password)
    |> click(Query.button("Submit"))
    |> fill_in(Query.text_field("firstName"), with: first)
    |> fill_in(Query.text_field("lastName"), with: last)
    |> click(Query.button("Submit"))
    |> assert_has(Query.css("#kc-main-content-page-container"))
  end

  @doc """
  Overrides `Wallaby.Browser.visit/2` with a small delay to reduce flakiness
  """
  def visit(parent, path) do
    parent
    |> Wallaby.Browser.visit(path)
    |> sleep(100)
  end

  def close_tab(session) do
    session
    |> close_window()
    |> window_handles()
    |> List.first()
    |> then(&focus_window(session, &1))
  end

  def last_tab(session) do
    session
    |> window_handles()
    |> List.last()
    |> then(&focus_window(session, &1))
  end
end
