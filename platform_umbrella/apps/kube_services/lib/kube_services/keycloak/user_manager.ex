defmodule KubeServices.Keycloak.UserManager do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Keycloak.AdminClient
  alias CommonCore.OpenApi.KeycloakAdminSchema.UserRepresentation

  require Logger

  @me __MODULE__
  @state_opts ~w(admin_client_target)a

  typedstruct module: State do
    field :admin_client_target, atom | pid, default: AdminClient
  end

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) do
    {state_opts, gen_opts} = opts |> Keyword.put_new(:name, @me) |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  def init(args) do
    {:ok, struct!(State, args)}
  end

  @spec create_user(atom | pid | {atom, any} | {:via, atom, any}, String.t(), Keyword.t() | map() | struct()) ::
          {:ok, binary()} | {:error, any()}
  def create_user(target \\ @me, realm, attributes) do
    GenServer.call(target, {:create_user, realm, attributes})
  end

  def handle_call({:create_user, realm, attributes}, _from, %{admin_client_target: act} = state) do
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
        :ok = EventCenter.Keycloak.broadcast(:create_user, user)
        {:reply, res, state}

      res ->
        Logger.warning("Unable to create user: #{inspect(res)}")
        {:reply, res, state}
    end
  end

  defp keyword_from_any(attributes) when is_struct(attributes), do: attributes |> Map.from_struct() |> Keyword.new()
  defp keyword_from_any(attributes), do: Keyword.new(attributes)
end
