defmodule CommonCore.Util.Images do
  @moduledoc """
  Utilities for parsing and extracting components from container image strings.

  This module provides functions to parse container image strings and extract
  their components (repository, image name, and version/tag).

  ## Image Format

  Container images follow the format: `[registry/]namespace/image:tag`

  Examples:
  - `nginx:1.21`
  - `docker.io/library/nginx:1.21`
  - `nvcr.io/nvidia/cuda:12.8.1-base-ubi9`
  - `registry.k8s.io/autoscaling/addon-resizer:1.8.23`

  ## Functions

  - `repository/1` - Extracts the repository (registry + namespace) part
  - `image/1` - Extracts just the image name (last path component before tag)
  - `version/1` - Extracts the version/tag part after the colon
  """

  @doc """
  Extracts the repository portion from a container image string.

  The repository includes the registry and namespace parts, but excludes
  the image name and tag.

  ## Examples

      iex> CommonCore.Util.Images.repository("nginx:1.21")
      ""

      iex> CommonCore.Util.Images.repository("docker.io/library/nginx:1.21")
      "docker.io/library"

      iex> CommonCore.Util.Images.repository("nvcr.io/nvidia/cuda:12.8.1-base-ubi9")
      "nvcr.io/nvidia"

      iex> CommonCore.Util.Images.repository("registry.k8s.io/autoscaling/addon-resizer:1.8.23")
      "registry.k8s.io/autoscaling"

      iex> CommonCore.Util.Images.repository("gcr.io/project/image:tag")
      "gcr.io/project"

      iex> CommonCore.Util.Images.repository("localhost:5000/team/myapp:v1.0")
      "localhost:5000/team"

  ## Edge Cases

      iex> CommonCore.Util.Images.repository("image")
      ""

      iex> CommonCore.Util.Images.repository("image:tag")
      ""

      iex> CommonCore.Util.Images.repository("namespace/image")
      "namespace"

  """
  @spec repository(String.t()) :: String.t()
  def repository(image_string) when is_binary(image_string) do
    {image_without_tag, _tag} = split_image_and_tag(image_string)

    parts = String.split(image_without_tag, "/")

    case parts do
      [_single] -> ""
      parts -> parts |> Enum.drop(-1) |> Enum.join("/")
    end
  end

  @doc """
  Extracts the image name from a container image string.

  The image name is the last path component before the tag (if present).

  ## Examples

      iex> CommonCore.Util.Images.image("nginx:1.21")
      "nginx"

      iex> CommonCore.Util.Images.image("docker.io/library/nginx:1.21")
      "nginx"

      iex> CommonCore.Util.Images.image("nvcr.io/nvidia/cuda:12.8.1-base-ubi9")
      "cuda"

      iex> CommonCore.Util.Images.image("registry.k8s.io/autoscaling/addon-resizer:1.8.23")
      "addon-resizer"

      iex> CommonCore.Util.Images.image("gcr.io/project/my-app:v1.0.0")
      "my-app"

      iex> CommonCore.Util.Images.image("localhost:5000/team/myapp:v1.0")
      "myapp"

  ## Edge Cases

      iex> CommonCore.Util.Images.image("image")
      "image"

      iex> CommonCore.Util.Images.image("namespace/image")
      "image"

      iex> CommonCore.Util.Images.image("deep/nested/namespace/image:tag")
      "image"

  """
  @spec image(String.t()) :: String.t()
  def image(image_string) when is_binary(image_string) do
    {image_without_tag, _tag} = split_image_and_tag(image_string)

    image_without_tag
    |> String.split("/")
    |> List.last()
  end

  @doc """
  Extracts the version/tag from a container image string.

  If no tag is specified, returns "latest" as the default.

  ## Examples

      iex> CommonCore.Util.Images.version("nginx:1.21")
      "1.21"

      iex> CommonCore.Util.Images.version("docker.io/library/nginx:1.21")
      "1.21"

      iex> CommonCore.Util.Images.version("nvcr.io/nvidia/cuda:12.8.1-base-ubi9")
      "12.8.1-base-ubi9"

      iex> CommonCore.Util.Images.version("registry.k8s.io/autoscaling/addon-resizer:1.8.23")
      "1.8.23"

      iex> CommonCore.Util.Images.version("gcr.io/project/my-app:v1.0.0")
      "v1.0.0"

      iex> CommonCore.Util.Images.version("localhost:5000/team/myapp:v1.0")
      "v1.0"

  ## Default Tag

      iex> CommonCore.Util.Images.version("nginx")
      "latest"

      iex> CommonCore.Util.Images.version("docker.io/library/nginx")
      "latest"

      iex> CommonCore.Util.Images.version("gcr.io/project/my-app")
      "latest"

  """
  @spec version(String.t()) :: String.t()
  def version(image_string) when is_binary(image_string) do
    {_image_without_tag, tag} = split_image_and_tag(image_string)
    tag
  end

  # Private helper function to split image string into image part and tag part
  # This correctly handles registries with ports (like localhost:5000)
  @spec split_image_and_tag(String.t()) :: {String.t(), String.t()}
  defp split_image_and_tag(image_string) do
    # Find the last colon that's followed by a tag (not part of a registry port)
    # We do this by finding all parts separated by colons and determining
    # if the last part looks like a tag vs part of a registry

    parts = String.split(image_string, ":")

    case parts do
      # No colons - no tag specified
      [image] ->
        {image, "latest"}

      # One colon - could be registry:port or image:tag
      [first, second] ->
        # If the second part contains a slash, it's likely registry:port/path
        # If it doesn't contain a slash and looks like a tag, it's image:tag
        if String.contains?(second, "/") do
          # This is registry:port/path - no tag specified
          {image_string, "latest"}
        else
          # This is image:tag
          {first, second}
        end

      # Multiple colons - need to find the tag
      _ ->
        # The tag is the last part, unless it contains a slash (then it's part of path)
        tag_candidate = List.last(parts)

        if String.contains?(tag_candidate, "/") do
          # Last part contains slash, so no tag specified
          {image_string, "latest"}
        else
          # Last part is the tag
          image_part = parts |> Enum.drop(-1) |> Enum.join(":")
          {image_part, tag_candidate}
        end
    end
  end
end
