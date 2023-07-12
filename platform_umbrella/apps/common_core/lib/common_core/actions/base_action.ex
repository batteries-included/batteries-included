defmodule CommonCore.Actions.BaseAction do
  use TypedStruct

  typedstruct do
    # create, sync, delete
    field :action, atom()

    # Realm, client, user
    field :type, atom()

    # The owning realm
    field :realm, :string, enforce: false

    # The code to call after creating this
    field :post_handler, atom()

    field :value, map(), enforce: false
  end
end
