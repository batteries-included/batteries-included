defmodule KubeResources.Gitea do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeResources.DevtoolsSettings
  alias KubeResources.IstioConfig.VirtualService

  @app "gitea"

  @data_path "/data"
  @init_path "/usr/sbin"
  @tmp_path "/tmp"

  @http_prefix "/x/gitea"

  @ssh_port 2200

  defp http_domain, do: "control.#{KubeState.IstioIngress.single_address()}.sslip.io"
  defp ssh_domain, do: "gitea.#{KubeState.IstioIngress.single_address()}.sslip.io"

  def virtual_service(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("gitea-http")
    |> B.spec(VirtualService.rewriting(@http_prefix, "gitea-http"))
  end

  def ssh_virtual_service(config) do
    namespace = DevtoolsSettings.namespace(config)

    B.build_resource(:virtual_service)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("gitea-ssh")
    |> B.spec(VirtualService.tcp_port(@ssh_port, "gitea-ssh", hosts: [ssh_domain()]))
  end

  def secret(config) do
    namespace = DevtoolsSettings.namespace(config)

    http_domain = http_domain()
    ssh_domain = ssh_domain()

    data = %{
      "_generals_" => "",
      "cache" => """
      ADAPTER=memory
      ENABLED=true
      INTERVAL=60
      """,
      "database" => """
      DB_TYPE=postgres
      HOST=pg-gitea.battery-core.svc.cluster.local
      NAME=gitea
      PASSWD=gitea
      USER=root
      SSL_MODE=require
      """,
      "metrics" => "ENABLED=true",
      "repository" => "ROOT=#{@data_path}/git/gitea-repositories",
      "security" => "INSTALL_LOCK=true",
      "server" => """
      APP_DATA_PATH=#{@data_path}
      DOMAIN=#{http_domain}
      ENABLE_PPROF=false
      HTTP_PORT=3000
      PROTOCOL=http
      ROOT_URL=http://#{http_domain}#{@http_prefix}
      SSH_DOMAIN=#{ssh_domain}
      SSH_LISTEN_PORT=@ssh_port
      SSH_PORT=@ssh_port
      """
    }

    B.build_resource(:secret)
    |> B.name("gitea-inline-config")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("stringData", data)
  end

  def secret_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    data = %{
      "app_ini.sh" => """
      #!/usr/bin/env bash
      set -euo pipefail

      function env2ini::log() {
        printf "${1}\\n"
      }

      function env2ini::read_config_to_env() {
        local section="${1}"
        local line="${2}"

        if [[ -z "${line}" ]]; then
          # skip empty line
          return
        fi

        # 'xargs echo -n' trims all leading/trailing whitespaces and a trailing new line
        local setting="$(awk -F '=' '{print $1}' <<< "${line}" | xargs echo -n)"

        if [[ -z "${setting}" ]]; then
          env2ini::log '  ! invalid setting'
          exit 1
        fi

        local value=''
        local regex="^${setting}(\\s*)=(\\s*)(.*)"
        if [[ $line =~ $regex ]]; then
          value="${BASH_REMATCH[3]}"
        else
          env2ini::log '  ! invalid setting'
          exit 1
        fi

        env2ini::log "    + '${setting}'"

        if [[ -z "${section}" ]]; then
          export "ENV_TO_INI____${setting^^}=${value}"
          # '^^' makes the variable content uppercase
          return
        fi

        local masked_section="${section//./_0X2E_}" # '//' instructs to replace all matches
        masked_section="${masked_section//-/_0X2D_}"

        export "ENV_TO_INI__${masked_section^^}__${setting^^}=${value}" # '^^' makes the variable content uppercase
      }

      function env2ini::reload_preset_envs() {
        env2ini::log "Reloading preset envs..."

        while read -r line; do
          if [[ -z "${line}" ]]; then
            # skip empty line
            return
          fi

          # 'xargs echo -n' trims all leading/trailing whitespaces and a trailing new line
          local setting="$(awk -F '=' '{print $1}' <<< "${line}" | xargs echo -n)"

          if [[ -z "${setting}" ]]; then
            env2ini::log '  ! invalid setting'
            exit 1
          fi

          local value=''
          local regex="^${setting}(\\s*)=(\\s*)(.*)"
          if [[ $line =~ $regex ]]; then
            value="${BASH_REMATCH[3]}"
          else
            env2ini::log '  ! invalid setting'
            exit 1
          fi

          env2ini::log "  + '${setting}'"

          export "${setting^^}=${value}"
          # '^^' makes the variable content uppercase
        done < "/tmp/existing-envs"

        rm /tmp/existing-envs
      }


      function env2ini::process_config_file() {
        local config_file="${1}"
        local section="$(basename "${config_file}")"

        if [[ $section == '_generals_' ]]; then
          env2ini::log "  [ini root]"
          section=''
        else
          env2ini::log "  ${section}"
        fi


        cat ${config_file}

        while read -r line; do
          env2ini::read_config_to_env "${section}" "${line}"
        done < <(awk 1 "${config_file}") # Helm .toYaml trims the trailing new line which breaks line processing; awk 1 ... adds it back while reading
      }

      function env2ini::load_config_sources() {
        local path="${1}"

        env2ini::log "Processing $(basename "${path}")..."

        while read -d '' configFile; do
          env2ini::process_config_file "${configFile}"
        done < <(find "${path}" -type l -not -name '..data' -print0)

        env2ini::log "\\n"
      }

      function env2ini::generate_initial_secrets() {
        # These environment variables will either be
        #   - overwritten with user defined values,
        #   - initially used to set up Gitea
        # Anyway, they won't harm existing app.ini files

        export ENV_TO_INI__SECURITY__INTERNAL_TOKEN=$(gitea generate secret INTERNAL_TOKEN)
        export ENV_TO_INI__SECURITY__SECRET_KEY=$(gitea generate secret SECRET_KEY)
        export ENV_TO_INI__OAUTH2__JWT_SECRET=$(gitea generate secret JWT_SECRET)

        env2ini::log "...Initial secrets generated\\n"
      }

      env | (grep ENV_TO_INI || [[ $? == 1 ]]) > /tmp/existing-envs

      # MUST BE CALLED BEFORE OTHER CONFIGURATION
      env2ini::generate_initial_secrets

      env2ini::load_config_sources '/env-to-ini-mounts/inlines/'
      env2ini::load_config_sources '/env-to-ini-mounts/additionals/'

      # load existing envs to override auto generated envs
      env2ini::reload_preset_envs

      env2ini::log "=== All configuration sources loaded ===\\n"

      # safety to prevent rewrite of secret keys if an app.ini already exists
      if [ -f ${GITEA_APP_INI} ]; then
        env2ini::log 'An app.ini file already exists. To prevent overwriting secret keys, these settings are dropped and remain unchanged:'
        env2ini::log '  - security.INTERNAL_TOKEN'
        env2ini::log '  - security.SECRET_KEY'
        env2ini::log '  - oauth2.JWT_SECRET'

        unset ENV_TO_INI__SECURITY__INTERNAL_TOKEN
        unset ENV_TO_INI__SECURITY__SECRET_KEY
        unset ENV_TO_INI__OAUTH2__JWT_SECRET
      fi

      environment-to-ini -o $GITEA_APP_INI -p ENV_TO_INI
      """,
      "init_directory_structure.sh" => """
      #!/usr/bin/env bash

      set -euo pipefail

      set -x
      chown 1000:1000 /data
      mkdir -p /data/git/.ssh
      chmod -R 700 /data/git/.ssh
      [ ! -d /data/gitea ] && mkdir -p /data/gitea/conf

      # prepare temp directory structure
      mkdir -p "${GITEA_TEMP}"
      chown 1000:1000 "${GITEA_TEMP}"
      chmod ug+rwx "${GITEA_TEMP}"
      """,
      "configure_gitea.sh" => """
      #!/usr/bin/env bash

      set -euo pipefail

      echo '==== BEGIN GITEA CONFIGURATION ===='

      { # try
        gitea migrate
      } || { # catch
        echo "Gitea migrate might fail due to database connection...This init-container will try again in a few seconds"
        exit 1
      }

      function configure_admin_user() {
        local ACCOUNT_ID=$(gitea admin user list --admin | grep -e "\\s+${GITEA_ADMIN_USERNAME}\\s+" | awk -F " " "{printf \\$1}")
        if [[ -z "${ACCOUNT_ID}" ]]; then
          echo "No admin user '${GITEA_ADMIN_USERNAME}' found. Creating now..."
          gitea admin user create --admin --username "${GITEA_ADMIN_USERNAME}" --password "${GITEA_ADMIN_PASSWORD}" --email "gitea@batteriesincl.com" --must-change-password=false
          echo '...created.'
        else
          echo "Admin account '${GITEA_ADMIN_USERNAME}' already exist. Running update to sync password..."
          gitea admin user change-password --username "${GITEA_ADMIN_USERNAME}" --password "${GITEA_ADMIN_PASSWORD}"
          echo '...password sync done.'
        fi
      }

      configure_admin_user

      echo '==== END GITEA CONFIGURATION ===='
      """
    }

    B.build_resource(:secret)
    |> B.name("gitea-init")
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> Map.put("stringData", data)
  end

  def service(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec =
      %{}
      |> B.short_selector(@app)
      |> B.ports([
        %{"targetPort" => 3000, "port" => 3000, "name" => "http"}
      ])

    B.build_resource(:service)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name("gitea-http")
    |> B.spec(spec)
  end

  def service_1(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec =
      %{}
      |> B.short_selector(@app)
      |> B.ports([
        %{
          "targetPort" => @ssh_port,
          "port" => @ssh_port,
          "protocol" => "TCP",
          "name" => "ssh"
        }
      ])

    B.build_resource(:service)
    |> B.app_labels(@app)
    |> B.namespace(namespace)
    |> B.name("gitea-ssh")
    |> B.spec(spec)
  end

  defp add_command(container, nil = _command), do: container
  defp add_command(container, command), do: Map.put(container, "command", [command])

  defp base_container(config, name, command \\ nil) do
    gitea_image = DevtoolsSettings.gitea_image(config)
    gitea_version = DevtoolsSettings.gitea_version(config)

    image_with_version = "#{gitea_image}:#{gitea_version}"

    pg_secret = DevtoolsSettings.gitea_user_secret_name(config)

    %{}
    |> Map.put("name", name)
    |> Map.put("image", image_with_version)
    |> Map.put("env", [
      %{"name" => "GITEA_CUSTOM", "value" => Path.join(@data_path, "/gitea")},
      %{"name" => "GITEA_APP_INI", "value" => Path.join(@data_path, "/gitea/conf/app.ini")},
      %{"name" => "GITEA_WORK_DIR", "value" => @data_path},
      %{"name" => "SSH_LISTEN_PORT", "value" => "@ssh_port"},
      %{"name" => "SSH_PORT", "value" => "@ssh_port"},
      %{"name" => "GITEA_TEMP", "value" => Path.join(@tmp_path, "/gitea")},
      %{"name" => "TMPDIR", "value" => Path.join(@tmp_path, "/gitea")},
      %{
        "name" => "ENV_TO_INI__DATABASE__USER",
        "valueFrom" => B.secret_key_ref(pg_secret, "username")
      },
      %{
        "name" => "ENV_TO_INI__DATABASE__PASSWD",
        "valueFrom" => B.secret_key_ref(pg_secret, "password")
      },

      # TODO Clean this up!
      %{"name" => "GITEA_ADMIN_USERNAME", "value" => "gitea_admin"},
      %{"name" => "GITEA_ADMIN_PASSWORD", "value" => "r8sA8CPHD9!bt6d"}
    ])
    |> Map.put("volumeMounts", [
      %{"name" => "init", "mountPath" => @init_path},
      %{"name" => "temp", "mountPath" => "/tmp"},
      %{"name" => "data", "mountPath" => @data_path},
      %{
        "name" => "inline-config-sources",
        "mountPath" => "/env-to-ini-mounts/inlines/"
      }
    ])
    |> add_command(command)
  end

  defp main_container(config) do
    config
    |> base_container("gitea")
    |> Map.put("ports", [
      %{"name" => "ssh", "containerPort" => 22},
      %{"name" => "http", "containerPort" => 3000}
    ])
    |> Map.put("livenessProbe", %{
      "failureThreshold" => 10,
      "initialDelaySeconds" => 200,
      "periodSeconds" => 10,
      "successThreshold" => 1,
      "tcpSocket" => %{"port" => "http"},
      "timeoutSeconds" => 1
    })
    |> Map.put("readinessProbe", %{
      "failureThreshold" => 3,
      "initialDelaySeconds" => 5,
      "periodSeconds" => 10,
      "successThreshold" => 1,
      "tcpSocket" => %{"port" => "http"},
      "timeoutSeconds" => 1
    })
  end

  def stateful_set(config) do
    namespace = DevtoolsSettings.namespace(config)

    spec = %{
      "replicas" => 1,
      "selector" => %{
        "matchLabels" => %{"battery/app" => @app}
      },
      "serviceName" => "gitea",
      "template" => %{
        "metadata" => %{
          "labels" => %{
            "battery/app" => "gitea",
            "battery/managed" => "true"
          }
        },
        "spec" => %{
          "securityContext" => %{"fsGroup" => 1000},
          "initContainers" => [
            # This one creates and chowns all the dirs needed
            base_container(
              config,
              "init-directories",
              "/usr/sbin/init_directory_structure.sh"
            ),
            # This one creates the ini
            base_container(config, "init-app-ini", "/usr/sbin/app_ini.sh"),

            # This migrates the database
            # It fails if run as root.
            config
            |> base_container("configure-gitea", "/usr/sbin/configure_gitea.sh")
            |> Map.put("securityContext", %{"runAsUser" => 1000})
          ],
          "terminationGracePeriodSeconds" => 60,
          "containers" => [
            main_container(config)
          ],
          "volumes" => [
            %{
              "name" => "init",
              "secret" => %{"secretName" => "gitea-init", "defaultMode" => 110}
            },
            %{"name" => "config", "secret" => %{"secretName" => "gitea", "defaultMode" => 110}},
            %{
              "name" => "inline-config-sources",
              "secret" => %{"secretName" => "gitea-inline-config"}
            },
            %{"name" => "temp", "emptyDir" => %{}}
          ]
        }
      },
      "volumeClaimTemplates" => [
        %{
          "metadata" => %{"name" => "data"},
          "spec" => %{
            "accessModes" => ["ReadWriteOnce"],
            "resources" => %{"requests" => %{"storage" => "10Gi"}}
          }
        }
      ]
    }

    B.build_resource(:stateful_set)
    |> B.namespace(namespace)
    |> B.app_labels(@app)
    |> B.name("gitea")
    |> B.spec(spec)
  end

  def materialize(config) do
    %{
      "/0/secret" => secret(config),
      "/1/secret_1" => secret_1(config),
      "/3/service" => service(config),
      "/4/service_1" => service_1(config),
      "/5/stateful_set" => stateful_set(config)
    }
  end
end
