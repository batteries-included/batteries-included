defmodule HomeBaseWeb.InstallationStatusJSON do
  @moduledoc false

  def show(%{jwt: jwt}) do
    %{jwt: data(jwt)}
  end

  defp data(jwt) do
    %{
      payload: Map.get(jwt, "payload"),
      protected: Map.get(jwt, "protected"),
      signature: Map.get(jwt, "signature")
    }
  end
end
