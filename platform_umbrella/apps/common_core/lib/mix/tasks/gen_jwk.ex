defmodule Mix.Tasks.Gen.Jwk do
  @shortdoc "Create a set of PEM jwk files."
  @moduledoc """
  Create a private and publice key set of JWK's as PEM files for
  use in signing responses from home_base.
  """

  use Mix.Task

  require Logger

  @base_path "apps/common_core/priv/keys"

  def run(args) do
    [name] = args

    base_path = Path.join(File.cwd!(), @base_path)
    File.mkdir_p!(base_path)

    private_key_file = Path.join(base_path, "#{name}.pem")
    public_key_file = Path.join(base_path, "#{name}.pub.pem")

    if File.exists?(private_key_file) do
      Logger.info("Removing existing private key files.")
      File.rm!(private_key_file)
    end

    if File.exists?(public_key_file) do
      Logger.info("Removing existing key files.")
      File.rm!(public_key_file)
    end

    {key, public} = generate_keys()

    write_key!(private_key_file, key)
    write_key!(public_key_file, public)

    Logger.info("Key files generated.")
  end

  defp write_key!(file, key) do
    {_, contents} = JOSE.JWK.to_pem(key)
    File.write!(file, contents)
    File.chmod!(file, 0o600)
  end

  defp generate_keys do
    key = CommonCore.JWK.generate_key()
    public = CommonCore.JWK.public_key(key)
    {key, public}
  end
end
