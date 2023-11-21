defmodule KubeServices.Keycloak.UserManager do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Keycloak.AdminClient
  alias CommonCore.OpenApi.KeycloakAdminSchema.CredentialRepresentation
  alias CommonCore.OpenApi.KeycloakAdminSchema.UserRepresentation
  alias EventCenter.Keycloak.Payload

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
      # UserRepresentation is a schema
      # struct which needs %{} for changesets
      |> Map.new()
      # Finally to a UserRepresentation struct for the AdminClient
      |> UserRepresentation.new!()

    case AdminClient.create_user(act, realm, user_rep) do
      {:ok, user} = res ->
        Logger.info("User created successfully: #{inspect(user)}")
        :ok = EventCenter.Keycloak.broadcast(%Payload{action: :create_user, resource: user})
        {:reply, res, state}

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
end
