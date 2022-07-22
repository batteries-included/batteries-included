defmodule Mix.Tasks.GenResource do
  @moduledoc "The mix task to generate a resource code module from yaml"
  use Mix.Task
  import KubeExt.Yaml

  @requirements ["app.config"]

  defmodule ResourceResult do
    defstruct methods: %{}, manifests: %{}, raw_files: %{}

    def merge(rr_one, rr_two) do
      %__MODULE__{
        methods: Map.merge(rr_one.methods, rr_two.methods),
        manifests: Map.merge(rr_one.manifests, rr_two.manifests),
        raw_files: Map.merge(rr_one.raw_files, rr_two.raw_files)
      }
    end
  end

  def run(args) do
    [file_path, app_name] = args

    result =
      file_path
      |> YamlElixir.read_all_from_file!()
      |> Enum.reject(&Enum.empty?/1)
      |> Enum.map(fn resource -> process_resource(resource) end)
      |> Enum.reduce(%ResourceResult{}, &ResourceResult.merge/2)

    write_manifests(result, app_name)
    write_resouce_elixir(result, app_name)
  end

  def write_resouce_elixir(%ResourceResult{} = result, app_name) do
    module = full_module(app_name, Map.values(result.methods))

    resource_path =
      Path.join(File.cwd!(), "apps/kube_resources/lib/kube_resources/#{app_name}.ex")

    File.write!(resource_path, Macro.to_string(module))
  end

  def write_manifests(%ResourceResult{} = result, app_name) do
    File.mkdir_p!("apps/kube_resources/priv/manifests/#{app_name}/")

    for {name, contents} <- result.manifests do
      path = "apps/kube_resources/priv/manifests/#{app_name}/#{name}"
      File.write!(path, contents)
    end
  end

  def process_resource(resource),
    do: process_resource(resource, KubeExt.ApiVersionKind.resource_type(resource))

  def process_resource(resource, :crd) do
    file_name = crd_file_name(resource)

    content =
      resource
      |> update_in(["metadata"], fn meta ->
        Map.drop(meta || %{}, ["annotations", "creationTimestamp"])
      end)
      |> to_yaml()

    manifests = Map.put(%{}, file_name, content)
    %ResourceResult{manifests: manifests}
  end

  def process_resource(resource, resource_type) do
    method_name = resource_method_name(resource_type, resource)

    method_def =
      resource
      |> Map.drop(["apiVersion", "kind"])
      |> Enum.reduce(starting_code(resource_type), fn {key, value}, acc_code ->
        handle_field(key, value, acc_code)
      end)
      |> then(fn rp ->
        resource_method_from_pipeline(rp, method_name)
      end)

    methods = Map.put(%{}, method_name, method_def)

    %ResourceResult{methods: methods}
  end

  defp handle_field("metadata" = _field_name, field_value, acc_code) do
    name = Map.get(field_value, "name", nil)
    namespace = Map.get(field_value, "namespace", nil)

    acc_code
    |> add_name(name)
    |> add_namespace(namespace)
    |> add_app_labels()
  end

  defp handle_field("spec" = _field_name, field_value, acc_code) do
    add_spec(acc_code, field_value)
  end

  defp handle_field(field_name, field_value, acc_code) do
    add_map_put_key(acc_code, field_name, field_value)
  end

  defp pipe(left, right) do
    quote do
      unquote(left) |> unquote(right)
    end
  end

  defp add_map_put_key(pipeline, key, value) do
    pipe(
      pipeline,
      quote do
        Map.put(unquote(key), unquote(value))
      end
    )
  end

  defp add_spec(pipeline, value) do
    pipe(
      pipeline,
      quote do
        B.spec(unquote(value))
      end
    )
  end

  defp add_name(pipeline, name) do
    pipe(
      pipeline,
      quote do
        B.name(unquote(name))
      end
    )
  end

  defp add_app_labels(pipeline) do
    pipe(
      pipeline,
      quote do
        B.app_labels(@app)
      end
    )
  end

  defp add_namespace(pipeline, nil), do: pipeline

  defp add_namespace(pipeline, _namespace) do
    pipe(
      pipeline,
      quote do
        B.namespace(namespace)
      end
    )
  end

  def starting_code(resource_type) do
    quote do
      B.build_resource(unquote(resource_type))
    end
  end

  def resource_method_name(resource_type, resource) do
    name =
      resource
      |> K8s.Resource.name()
      |> Macro.underscore()
      |> String.replace(~r/[^a-zA-Z\d]/, "_")

    :"#{Atom.to_string(resource_type)}_#{name}"
  end

  defp resource_method_from_pipeline(pipeline, method_name) do
    quote do
      def unquote(method_name)(config) do
        namespace = Settings.namespace(config)
        unquote(pipeline)
      end
    end
  end

  defp full_module(app_name, methods) do
    quote do
      defmodule KubeResources.Resource do
        alias KubeExt.Builder, as: B
        @app unquote(app_name)

        unquote_splicing(methods)
      end
    end
  end

  defp crd_file_name(resource) do
    sanitized_name =
      resource |> K8s.Resource.name() |> String.downcase() |> String.replace(~r/[^\w]/, "_")

    "#{sanitized_name}.yaml"
  end
end
