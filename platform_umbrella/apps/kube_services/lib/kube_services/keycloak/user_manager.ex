defmodule KubeServices.Keycloak.UserManager do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.OpenAPI.KeycloakAdminSchema.ClientRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.CredentialRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.RoleRepresentation
  alias CommonCore.OpenAPI.KeycloakAdminSchema.UserRepresentation
  alias EventCenter.Keycloak.Payload
  alias KubeServices.Keycloak.AdminClient

  require Logger

  @me __MODULE__
  @state_opts ~w(admin_client_target)a

  @temp_creds_length 5

  typedstruct module: State do
    field :admin_client_target, atom | pid, default: AdminClient
  end

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) do
    {state_opts, gen_opts} = opts |> Keyword.put_new(:name, @me) |> Keyword.split(@state_opts)

    Logger.debug("Starting UserManager")

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(args) do
    {:ok, struct!(State, args)}
  end

  @spec create(
          atom | pid | {atom, any} | {:via, atom, any},
          String.t(),
          Keyword.t() | map() | struct()
        ) ::
          {:ok, binary()} | {:error, any()}
  def create(target \\ @me, realm, attributes) do
    GenServer.call(target, {:create, realm, attributes})
  end

  def reset_password(target \\ @me, realm, user_id) do
    GenServer.call(target, {:reset_password, realm, user_id})
  end

  @spec make_realm_admin(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, String.t(), binary()) ::
          :ok | {:error, any()}
  def make_realm_admin(target \\ @me, realm, user_id) do
    GenServer.call(target, {:make_realm_admin, realm, user_id})
  end

  @spec find_realm_managment_client([ClientRepresentation.t()]) :: ClientRepresentation.t() | nil
  defp find_realm_managment_client(clients) do
    Enum.find(clients, fn client -> client.clientId == "realm-management" end)
  end

  @spec find_realm_admin_role([RoleRepresentation.t()]) :: RoleRepresentation.t() | nil
  defp find_realm_admin_role(roles) do
    Enum.find(roles, fn role -> role.name == "realm-admin" end)
  end

  defp find_admin_role(roles) do
    Enum.find(roles, fn role -> role.name == "admin" end)
  end

  @spec add_realm_admin_role(String.t(), String.t()) :: [map()]
  defp add_realm_admin_role(role_id, client_id) do
    [
      %{
        "id" => role_id,
        "name" => "realm-admin",
        "description" => "${role_realm-admin}",
        "composite" => true,
        "clientRole" => true,
        "containerId" => client_id
      }
    ]
  end

  defp add_admin_role(role_id) do
    [
      %{
        "id" => role_id,
        "name" => "admin",
        "description" => "Admin",
        "composite" => true,
        "clientRole" => false
      }
    ]
  end

  def handle_call({:make_realm_admin, realm, user_id}, _from, state) when realm == "master" do
    # When the realm is master we have a special process
    #
    # Add the realm role "admin" role to the user
    with {:ok, roles} <- AdminClient.roles(realm),
         %{} = role <- find_admin_role(roles),
         payload = add_admin_role(role.id),
         {:ok, _success} <- AdminClient.add_roles(realm, user_id, payload) do
      {:reply, :ok, state}
    else
      {:error, res} ->
        Logger.warning("Unable to make user realm admin: #{inspect(res)}")
        {:reply, {:error, res}, state}

      res ->
        Logger.warning("Unable to make user realm admin unkown error: #{inspect(res)}")
        {:reply, {:error, res}, state}
    end
  end

  def handle_call({:make_realm_admin, realm, user_id}, _from, state) do
    # Get all the clients from the realm
    with {:ok, clients} <- AdminClient.clients(realm),
         # Find the realm management client that controls
         # access to the realm settings
         %{} = managment_client <- find_realm_managment_client(clients),
         # Get all the roles for the realm management client
         {:ok, roles} <- AdminClient.client_roles(realm, managment_client.id),
         # Frind the one that makes us and admin
         %{} = role <- find_realm_admin_role(roles),
         # Create a payload to add the role to the user
         payload = add_realm_admin_role(role.id, managment_client.id),
         # Tell Keycloak to add the role to the user
         {:ok, _success} <- AdminClient.add_client_roles(realm, user_id, managment_client.id, payload) do
      {:reply, :ok, state}
    else
      {:error, res} ->
        Logger.warning("Unable to make user realm admin: #{inspect(res)}")
        {:reply, {:error, res}, state}

      res ->
        Logger.warning("Unable to make user realm admin unkown error: #{inspect(res)}")
        {:reply, {:error, res}, state}
    end
  end

  def handle_call({:create, realm, attributes}, _from, %{admin_client_target: act} = state) do
    user_rep =
      attributes
      |> keyword_from_any()
      # Manipulate the attributes to add enabled.
      # It's really needed if the user is trying to
      # add someone they expect to be able to use that
      # user. And we don't want to have a full user UI
      # for a while.
      |> Keyword.put_new(:enabled, true)
      # Add a batt ID if one isn't specified
      |> Keyword.update(:id, nil, fn
        nil -> CommonCore.Ecto.BatteryUUID.autogenerate()
        x -> x
      end)
      # UserRepresentation is a schema
      # struct which needs %{} for changesets
      |> Map.new()
      # Finally to a UserRepresentation struct for the AdminClient
      |> UserRepresentation.new!()

    case AdminClient.create_user(act, realm, user_rep) do
      # TODO: `user_url` is invalid and results in a 401
      {:ok, user_url} ->
        Logger.info("User created successfully: #{inspect(user_url)}")
        :ok = EventCenter.Keycloak.broadcast(%Payload{action: :create_user, resource: %{id: user_rep.id, realm: realm}})

        # Send the user ID back to the liveview so it can be used to generate a temp password
        {:reply, {:ok, extract_user_id_from_url(user_url)}, state}

      res ->
        Logger.warning("Unable to create user: #{inspect(res)}")
        {:reply, res, state}
    end
  end

  def handle_call({:reset_password, realm, user_id}, _from, %{admin_client_target: act} = state) do
    # Create an easy to read and write password that is secure
    temp_creds = @temp_creds_length |> MnemonicSlugs.Wordlist.get_words() |> Enum.join(" ")

    # It's always a temporary password
    cred = %CredentialRepresentation{temporary: true, value: temp_creds}

    # Reset the password
    case AdminClient.reset_password_user(act, realm, user_id, cred) do
      {:ok, _} = _res ->
        # If it worked then broadcast so we can have timeline events.
        Logger.info("User password reset successfully: #{inspect(user_id)}")

        :ok =
          EventCenter.Keycloak.broadcast(%Payload{
            action: :reset_user_password,
            resource: %{id: user_id, realm: realm}
          })

        {:reply, {:ok, temp_creds}, state}

      res ->
        Logger.warning("Unable reset user password: #{inspect(res)}")
        {:reply, res, state}
    end
  end

  defp keyword_from_any(attributes) when is_struct(attributes), do: attributes |> Map.from_struct() |> Keyword.new()

  defp keyword_from_any(attributes), do: Keyword.new(attributes)

  defp extract_user_id_from_url(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> String.split("/")
    |> List.last()
  end
end
