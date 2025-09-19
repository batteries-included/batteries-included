defmodule Verify.SSOTest do
  use Verify.Images

  use Verify.TestCase,
    async: false,
    batteries: [keycloak: %{admin_username: "batteryadmin", admin_password: "password"}],
    images: ~w(keycloak)a

  alias Verify.BatteryInstallWorker

  # don't install sso battery here. we need to create user first
  @user "test"
  @password "password"

  setup_all %{battery_install_worker: install_pid, image_pull_worker: pull_pid, control_url: url} do
    wrap do
      # we don't need to wait for these. We can install and setup SSO while these are pulling
      prepull_images(pull_pid, ~w(grafana oauth2_proxy)a ++ @victoria_metrics)

      {:ok, session} = start_session(url)

      session =
        session
        |> check_keycloak_running()
        |> navigate_to_keycloak_realm("Batteries Included")
        |> create_keycloak_user("test@batteriesincl.com", @user, @password, "Batteries", "Included")

      :ok = install_batteries(install_pid, :sso)
      Wallaby.end_session(session)

      # having an already logged in session will be helpful
      {:ok, session} = start_session(url)

      authenticated_session =
        session
        |> visit("/")
        |> login_keycloak(@user, @password)

      # use it for installing future batteries
      BatteryInstallWorker.set_session(install_pid, authenticated_session)

      {:ok, authenticated_session: authenticated_session}
    end
  end

  verify "control-server prompts for login", %{session: session} do
    session
    |> visit("/")
    |> login_keycloak(@user, @password)
    |> assert_has(h3("Home"))
  end

  verify "grafana (native SSO) prompts for login", %{
    session: session,
    authenticated_session: authenticated_session,
    battery_install_worker: install,
    image_pull_worker: pull
  } do
    :ok = wait_for_images(pull, [:grafana])
    :ok = install_batteries(install, :grafana)

    # use the authenticated_session to determine the grafana url
    url =
      authenticated_session
      # make sure the client exists
      |> navigate_to_keycloak_realm("Batteries Included")
      |> assert_has(Query.css("table#keycloak-clients-table tr td", text: "grafana-oauth"))
      # trigger reconcile to update the config
      |> trigger_k8s_deploy()
      |> assert_pods_in_deployment_running("battery-core", "grafana")
      |> visit("/monitoring")
      |> click_external(Query.css("a", text: "Grafana"))
      |> close_tab()
      |> attr(Query.css("a", text: "Grafana"), "href")

    session
    # the grafana config flaps as the realm is created
    # we've tried to obviate it above but there's not
    # a perfect way to check that grafana has rolled out
    |> visit(url)
    |> login_keycloak(@user, @password)
    # find the link to the website in the footer
    |> assert_has(Query.css("h1", text: "Welcome to Grafana"))

    uninstall_batteries(install, :grafana)
  end

  verify "vmagent (oauth2_proxy) prompts for login", %{
    session: session,
    authenticated_session: authenticated_session,
    battery_install_worker: install,
    image_pull_worker: pull
  } do
    :ok = wait_for_images(pull, @victoria_metrics)
    :ok = install_batteries(install, :victoria_metrics)
    ns = "battery-core"

    # use the authenticated_session to determine the url
    url =
      authenticated_session
      |> assert_pods_in_deployment_running(ns, "vm-operator")
      |> assert_pods_in_deployment_running(ns, "vmagent-main-agent")
      |> assert_pods_in_sts_running(ns, "vmstorage-main-cluster")
      |> assert_pods_in_sts_running(ns, "vmselect-main-cluster")
      |> assert_pods_in_deployment_running(ns, "vminsert-main-cluster")
      |> visit("/monitoring")
      |> attr(Query.css("a", text: "VM Agent"), "href")

    session
    |> visit(url)
    |> login_keycloak(@user, @password)
    |> assert_has(Query.css("h2", text: "vmagent"))

    uninstall_batteries(install, :victoria_metrics)
  end
end
