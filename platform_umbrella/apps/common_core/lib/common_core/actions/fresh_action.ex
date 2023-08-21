defmodule CommonCore.Actions.FreshGeneratedAction do
  @doc """
  FreshGeneratedAction is a struct to hold information about
  what actions the systems has just generated. They are not
  actions stored in the database via ecto.

  These are transitory and will be re-created at will.
  """
  use TypedStruct

  typedstruct do
    # create, delete
    field :action, atom()

    # Realm, client, user
    field :type, atom()

    # The owning realm
    field :realm, :string, enforce: false

    field :value, map(), enforce: false
  end
end
