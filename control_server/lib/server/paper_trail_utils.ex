defmodule Server.PaperTrailUtils do
  def unwrap_papertrail({:ok, %{model: model, version: _version}}) do
    {:ok, model}
  end

  def unwrap_papertrail({:error, result}) do
    {:error, result}
  end
end
