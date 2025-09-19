defmodule Verify.HomeBaseTest do
  use Verify.Images
  use Verify.TestCase, async: false, batteries: ~w(traditional_services)a

  alias CommonCore.Defaults
  alias CommonCore.Defaults.Images
  alias Verify.KindInstallWorker

  require Logger

  @show_traditional_path ~r(/traditional_services/[\d\w-]+/show$)
  @bat_trad_dropdown_entry Query.css(~s|input[value="battery-traditional"]|)
  @save_button Query.button("Save")

  @email "test@batteriesincl.com"
  @password "really good testing password"

  setup_all %{kube_config_path: kube_config_path, control_url: url} do
    {:ok, session} = start_session(url)

    # make sure the namespace is created
    session =
      session
      |> trigger_k8s_deploy()
      |> sleep(1_000)

    # get the seed data from the int-prod bootstrap file
    home_base_seed_data =
      File.cwd!()
      |> Path.join("../../../bootstrap/int-prod.spec.json")
      |> File.read!()
      |> Jason.decode!()
      |> Kernel.get_in(~w(initial_resources /config_map/home_base_seed_data))

    # apply it to the running cluster
    {:ok, conn} = K8s.Conn.from_file(kube_config_path, insecure_skip_tls_verify: true)
    op = K8s.Client.apply(home_base_seed_data)

    case retry(fn -> K8s.Client.run(conn, op) end) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        raise "#{inspect(reason)}"
    end

    # get the team id from the bootstrap data
    team =
      home_base_seed_data
      |> Map.get("data")
      |> Enum.find_value(fn {k, v} ->
        if String.contains?(k, ".team.json"), do: v
      end)
      |> Jason.decode!()

    session
    |> create_home_base(team["id"])
    |> Wallaby.end_session()

    :ok
  end

  verify "can create install", %{session: session, kind_install_worker: pid} do
    install_name = "int-test-#{:rand.uniform(10_000)}"

    {url, session} = navigate_to_home_base(session)

    session =
      session
      |> home_base_login()
      |> visit_relative("../installations/new")
      |> assert_text("Create a new installation")
      |> fill_in_name("installation[slug]", install_name)
      |> find(Query.select("installation[kube_provider]"), &click(&1, Query.option("Kind")))
      |> find(Query.select("installation[default_size]"), &click(&1, Query.option("Tiny")))
      |> click(Query.button("Create Installation"))
      # make sure we're on the success page
      |> assert_text("Installation Created")
      |> assert_path(~r|/installations/[\d\w-]+/success$|)

    cmd = text(session, Query.css("pre"))

    uri = URI.new!(url)

    {:ok} =
      try do
        KindInstallWorker.start_from_command(pid, cmd, install_name, uri.host)
      catch
        :exit, value ->
          # catch the exit and raise so that verify will run rage
          Logger.error("failed to create home-base cluster: #{inspect(value)}")
          raise inspect(value)
      end
  end

  defp navigate_to_home_base(session) do
    session =
      session
      |> visit("/traditional_services")
      |> assert_has(table_row(text: "home-base-"))

    id = text(session, Query.css("table tr td:first-child"))
    link = Query.link("running_service_#{id}")

    {attr(session, link, "href"), session |> click(link) |> close_tab() |> last_tab()}
  end

  defp create_home_base(session, team_id) do
    image = Images.home_base_image()
    service_name = "home-base-#{:rand.uniform(10_000)}"

    session
    |> add_pg_cluster(service_name)
    |> assert_pod_succeeded("pg-#{service_name}-1-initdb")
    |> assert_pod_running("pg-#{service_name}-1")
    |> create_traditional_service(
      service_name,
      size: "Small",
      image: image,
      port: "4000",
      callback: create_home_base_callback(service_name, team_id)
    )
    # verify we're on the show page
    |> assert_has(h3(service_name))
    |> assert_path(@show_traditional_path)
    # Make sure that this page has the kubernetes elements
    |> assert_has(Query.text("Pods"))
    |> click(Query.text("Pods"))
    # Assert that the first pod is there.
    |> assert_has(table_row(text: service_name, count: 1))
    |> assert_pod_running(service_name)
    # make sure we can access the running service
    |> visit_running_service()
    |> assert_has(Query.css("h2", text: "Log in to your account"))
    |> visit_relative("../signup")
    |> assert_has(Query.css("h2", text: "Sign up for an account"))
    |> fill_in(Query.text_field("user[email]"), with: @email)
    |> fill_in(Query.text_field("user[password]"), with: @password)
    |> fill_in(Query.text_field("user[password_confirmation]"), with: @password)
    |> click(Query.checkbox("user[terms]"))
    |> click(Query.button("Create account"))
    |> sleep(250)
    |> click(Query.link("Log in"))
    |> home_base_login()
  end

  defp home_base_login(session) do
    session
    |> assert_has(Query.css("h2", text: "Log in to your account"))
    |> fill_in(Query.text_field("user[email]"), with: @email)
    |> fill_in(Query.text_field("user[password]"), with: @password)
    |> click(Query.button("Log in"))
  end

  defp create_home_base_callback(service_name, team_id) do
    test_jwk =
      File.cwd!()
      |> Path.join("../../apps/common_core/priv/keys/test.pem")
      |> File.read!()
      |> JOSE.JWK.from_pem()
      |> JOSE.JWK.to_binary()
      |> elem(1)

    fn session ->
      session
      |> add_init_container()
      # set up DB creds from secret
      |> add_env_var_from_secret("cloudnative-pg.pg-#{service_name}.root", "username", "POSTGRES_USER")
      |> add_env_var_from_secret("cloudnative-pg.pg-#{service_name}.root", "password", "POSTGRES_PASSWORD")
      |> add_env_var_from_secret("cloudnative-pg.pg-#{service_name}.root", "hostname", "POSTGRES_HOST")
      |> add_explicit_var("POSTGRES_DB", "home-base")
      # add misc needed env vars
      |> add_explicit_var("POSTMARK_KEY", "abc123")
      |> add_explicit_var("BATTERY_TEAM_IDS", team_id)
      |> add_explicit_var("SECRET_KEY_BASE", Defaults.random_key_string())
      |> add_explicit_var("HOME_JWK", test_jwk)
      # add home-base-seed-data
      |> add_cm_volume("home-base-seed-data", false)
      |> add_cm_mount("home-base-seed-data", "/etc/init-config/")
    end
  end

  defp add_init_container(session) do
    session
    # add init container
    |> find(Query.css("#containers_panel-init_containers"), &click(&1, Query.button("Add Container")))
    |> fill_in(Query.text_field("container[name]"), with: "home-base-init")
    |> fill_in(Query.text_field("container[image]"), with: Images.home_base_image())
    |> fill_in(Query.text_field("container[path]"), with: "/app/bin/start")
    |> click(Query.button("Add argument"))
    |> fill_in(Query.text_field("container[args][]"), with: "home_base_init")
    |> click_modal_save("container")
    # make sure the modal is gone
    |> sleep(100)
    |> immediately_refute_has(Query.css("#container-form-modal"))
  end

  defp add_env_var_from_secret(session, secret_name, secret_key, name) do
    session
    |> click(Query.button("Add Variable"))
    |> click(Query.link("Secret"))
    |> fill_in(Query.text_field("env_value[name]"), with: name)
    |> find(Query.select("env_value[source_name]"), &click(&1, Query.option(secret_name)))
    |> find(Query.select("env_value[source_key]"), &click(&1, Query.option(secret_key)))
    |> click_modal_save("env_value")
    # make sure modal is gone
    |> sleep(100)
    |> immediately_refute_has(Query.css("#env_value-form-modal"))
  end

  defp add_explicit_var(session, key, value) do
    session
    |> click(Query.button("Add Variable"))
    |> fill_in(Query.text_field("env_value[name]"), with: key)
    |> fill_in(Query.text_field("env_value[value]"), with: value)
    |> click_modal_save("env_value")
    # make sure modal is gone
    |> sleep(100)
    |> immediately_refute_has(Query.css("#env_value-form-modal"))
  end

  defp add_pg_cluster(session, cluster_name) do
    session
    # create new cluster
    |> visit("/postgres/new")
    |> assert_has(h3("New Postgres Cluster"))
    |> fill_in_name("cluster[name]", cluster_name)
    |> click(Query.button("edit_user_root"))
    |> click(Query.css("div#div_postgres-user-namespace-dropdown"))
    |> then(fn sess ->
      sess =
        if selected?(sess, @bat_trad_dropdown_entry) do
          sess
        else
          click(sess, @bat_trad_dropdown_entry)
        end

      click(sess, Query.button("Update User"))
    end)
    |> click(@save_button)
  end

  defp add_cm_volume(session, name, optional) do
    optional_checkbox = Query.checkbox("volume[optional]")

    session
    |> find(Query.css("#volume_panel"), &click(&1, Query.button("Add Volume")))
    |> fill_in(Query.text_field("volume[name]"), with: name)
    |> click(Query.link("Config Map"))
    |> find(Query.select("volume[source_name]"), &click(&1, Query.option(name)))
    |> then(fn sess ->
      cond do
        # needs to be checked
        optional && !selected?(sess, optional_checkbox) ->
          click(sess, optional_checkbox)

        # needs to be unchecked
        !optional && selected?(sess, optional_checkbox) ->
          click(sess, optional_checkbox)

        true ->
          sess
      end
    end)
    |> click_modal_save("volume")
    # make sure modal is gone
    |> sleep(100)
    |> immediately_refute_has(Query.css("#volume-form-modal"))
  end

  defp add_cm_mount(session, name, path) do
    session
    |> find(Query.css("#mount_panel"), &click(&1, Query.button("Add Volume Mount")))
    |> find(Query.select("mount[volume_name]"), &click(&1, Query.option(name)))
    |> fill_in(Query.text_field("mount[mount_path]"), with: path)
    |> click_modal_save("mount")
    # make sure modal is gone
    |> sleep(100)
    |> immediately_refute_has(Query.css("#mount-form-modal"))
  end

  defp click_modal_save(session, modal),
    do: find(session, Query.css("##{modal}-form-modal-modal-container"), &click(&1, @save_button))
end
