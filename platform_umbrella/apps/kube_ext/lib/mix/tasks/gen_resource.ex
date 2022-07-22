defmodule Mix.Tasks.GenResource do
  @moduledoc "The mix task to generate a resource code module from yaml"
  use Mix.Task
  import KubeExt.Yaml
  import KubeExt.ApiVersionKind, only: [resource_type: 1]

  @requirements ["app.config"]

  @bad_labels [
    "app.kubernetes.io/managed-by",
    "app.kubernetes.io/version",
    "helm.sh/chart",
    "helm.sh/hook-delete-policy",
    "install.operator.istio.io/owning-resource",
    "chart",
    "release",
    "heritage"
  ]

  @max_config_string_size 256

  defmodule ResourceResult do
    defstruct methods: %{}, manifests: %{}, raw_files: %{}, include_paths: %{}

    def merge(rr_one, rr_two) do
      %__MODULE__{
        methods: Map.merge(rr_one.methods, rr_two.methods),
        manifests: Map.merge(rr_one.manifests, rr_two.manifests),
        raw_files: Map.merge(rr_one.raw_files, rr_two.raw_files),
        include_paths: Map.merge(rr_one.include_paths, rr_two.include_paths)
      }
    end
  end

  def run(args) do
    [file_path, app_name] = args

    result =
      file_path
      |> YamlElixir.read_all_from_file!()
      |> Enum.reject(&Enum.empty?/1)
      |> Enum.map(fn resource -> process_resource(resource, app_name) end)
      |> Enum.reduce(%ResourceResult{}, &ResourceResult.merge/2)

    write_manifests(result, app_name)
    write_raw_files(result, app_name)
    write_resouce_elixir(result, app_name)
  end

  defp write_resouce_elixir(%ResourceResult{} = result, app_name) do
    module = module(app_name, result.methods, result.include_paths)

    resource_path =
      Path.join(File.cwd!(), "apps/kube_resources/lib/kube_resources/#{app_name}.ex")

    File.write!(resource_path, Macro.to_string(module))
  end

  defp write_manifests(%ResourceResult{} = result, app_name) do
    File.mkdir_p!("apps/kube_resources/priv/manifests/#{app_name}/")

    for {name, contents} <- result.manifests do
      path = crd_path(app_name, name)
      File.write!(path, contents)
    end
  end

  defp write_raw_files(%ResourceResult{} = result, app_name) do
    File.mkdir_p!("apps/kube_resources/priv/raw_files/#{app_name}/")

    for {name, contents} <- result.raw_files do
      path = raw_file_path(app_name, name)
      File.write!(path, contents)
    end
  end

  defp crd_path(app_name, crd_filename),
    do: "apps/kube_resources/priv/manifests/#{app_name}/#{crd_filename}"

  defp raw_file_path(app_name, filename),
    do: "apps/kube_resources/priv/raw_files/#{app_name}/#{filename}"

  defp relative_crd_path(app_name, crd_filename), do: "priv/manifests/#{app_name}/#{crd_filename}"
  defp relative_raw_file_path(app_name, filename), do: "priv/raw_files/#{app_name}/#{filename}"

  def process_resource(resource, app_name),
    do: process_resource(resource, resource_type(resource), app_name)

  def process_resource(resource, :crd = _resource_type, app_name) do
    file_name = crd_file_name(resource)
    include_name = crd_include_name(resource)
    method_name = resource_method_name(resource, app_name)

    manifests = Map.put(%{}, file_name, to_yaml_contents(resource))
    includes = Map.put(%{}, include_name, relative_crd_path(app_name, file_name))
    methods = Map.put(%{}, method_name, yaml_resource_method(method_name, include_name))
    %ResourceResult{manifests: manifests, include_paths: includes, methods: methods}
  end

  def process_resource(resource, :config_map = _resource_type, app_name) do
    data = Map.get(resource, "data", %{})

    # These are the items that will be include
    large_data =
      data
      |> Enum.filter(fn {_key, value} ->
        is_binary(value) && String.length(value) >= @max_config_string_size
      end)
      |> Enum.into(%{})

    mappings =
      large_data
      |> Enum.map(fn {file_name, _} ->
        {to_include_name(file_name), relative_raw_file_path(app_name, file_name)}
      end)
      |> Enum.into(%{})

    # these are the values that we'll add ourself
    small_data = Map.drop(data, Map.keys(large_data))

    method_name = resource_method_name(resource, app_name)

    method_def = config_map_method(resource, method_name, app_name, small_data, large_data)

    methods = Map.put(%{}, method_name, method_def)

    %ResourceResult{raw_files: large_data, include_paths: mappings, methods: methods}
  end

  def process_resource(resource, resource_type, app_name) do
    method_name = resource_method_name(resource, app_name)

    method_def = default_method(resource, method_name, resource_type, app_name)
    methods = Map.put(%{}, method_name, method_def)
    %ResourceResult{methods: methods}
  end

  defp to_yaml_contents(resource) do
    resource
    |> update_in(["metadata"], fn meta ->
      Map.drop(meta || %{}, ["annotations", "creationTimestamp"])
    end)
    |> Map.drop(["state"])
    |> to_yaml()
  end

  defp default_method(resource, method_name, resource_type, app_name) do
    resource
    |> resource_pipeline(resource_type, app_name)
    |> resource_method_from_pipeline(method_name)
  end

  defp config_map_method(resource, method_name, app_name, small_data, large_data) do
    data_pipeline = data_pipeline(small_data, large_data)

    normal_pipeline =
      resource
      |> Map.drop(["data"])
      |> resource_pipeline(:config_map, app_name)
      |> add_data_from_var()

    resource_method_from_pipeline_and_data(data_pipeline, normal_pipeline, method_name)
  end

  defp resource_pipeline(resource, resource_type, app_name) do
    resource
    |> Map.drop(["apiVersion", "kind", "type"])
    |> Enum.reject(fn {_key, value} -> value == nil end)
    |> Enum.reduce(starting_code(resource_type), fn {key, value}, acc_code ->
      handle_field(key, value, acc_code, app_name)
    end)
  end

  defp data_pipeline(small_data, large_data) do
    Enum.reduce(small_data, starting_data(), fn {key, value}, code ->
      add_map_put_key(code, key, value)
    end)
    |> then(fn code_with_small ->
      Enum.reduce(large_data, code_with_small, fn {key, _value}, code ->
        add_map_put_get_resource(code, key, to_include_name(key))
      end)
    end)
  end

  defp yaml_resource_method(method_name, include_name) do
    quote do
      def unquote(method_name)(_config) do
        yaml(get_resource(unquote(include_name)))
      end
    end
  end

  defp handle_field("metadata" = _field_name, field_value, acc_code, app_name) do
    name = Map.get(field_value, "name", nil)
    namespace = Map.get(field_value, "namespace", nil)

    acc_code
    |> add_name(name)
    |> add_namespace(namespace)
    |> add_app_labels()
    |> add_other_labels(field_value, app_name)
  end

  defp handle_field("spec" = _field_name, field_value, acc_code, app_name) do
    add_spec(acc_code, clean_spec(field_value, app_name))
  end

  defp handle_field("rules" = _field_name, field_value, acc_code, _app_name) do
    add_rules(acc_code, field_value)
  end

  defp handle_field("roleRef" = _field_name, field_value, acc_code, _app_name) do
    add_role_ref(acc_code, Map.get(field_value, "name"))
  end

  defp handle_field("subjects" = _field_name, subjects, acc_code, _app_name) do
    Enum.reduce(subjects, acc_code, fn subject, code ->
      add_subject(code, Map.get(subject, "name"))
    end)
  end

  defp handle_field(field_name, field_value, acc_code, _app_name) do
    add_map_put_key(acc_code, field_name, field_value)
  end

  defp clean_spec(spec, app_name) do
    spec
    |> Enum.map(fn {key, value} -> clean_spec_field(key, value, app_name) end)
    |> Enum.into(%{})
  end

  defp clean_spec_field("selector", %{"matchLabels" => label_map}, app_name) do
    {"selector", %{"matchLabels" => clean_labels(label_map, app_name)}}
  end

  defp clean_spec_field("selector", %{} = label_map, app_name) do
    {"selector", clean_labels(label_map, app_name)}
  end

  defp clean_spec_field("template", template, app_name) do
    clean_template =
      template
      |> Enum.map(fn {key, value} ->
        case {key, value} do
          {"metadata", _} -> {"metadata", clean_template_metadata(value, app_name)}
          {_, _} -> {key, value}
        end
      end)
      |> Enum.into(%{})

    {"template", clean_template}
  end

  defp clean_spec_field(key, value, _app_name) do
    {key, value}
  end

  defp clean_labels(label_map, app_name) do
    label_map
    |> Map.drop(@bad_labels)
    |> Enum.map(fn {key, value} ->
      case {key, value} do
        {"app.kubernetes.io/instance", _} ->
          {"battery/app", app_name}

        {"app.kubernetes.io/component", _} ->
          {"battery/component", value}

        {"app.kubernetes.io/name", _} ->
          {"battery/component", value}

        {_, _} ->
          {key, value}
      end
    end)
    |> Enum.into(%{})
  end

  defp clean_template_metadata(metadata, app_name) do
    metadata
    |> Map.drop(["annotations"])
    |> update_in(["labels"], fn labels ->
      (labels || %{})
      |> clean_labels(app_name)
      |> Map.put("battery/app", app_name)
      |> Map.put("battery/managed", "true")
    end)
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

  defp add_map_put_get_resource(pipeline, key, resource_key) do
    pipe(
      pipeline,
      quote do
        Map.put(unquote(key), get_resource(unquote(resource_key)))
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

  defp add_role_ref(pipeline, name) do
    pipe(
      pipeline,
      quote do
        B.role_ref(B.build_role_ref(unquote(name)))
      end
    )
  end

  defp add_subject(pipeline, name) do
    pipe(
      pipeline,
      quote do
        B.subject(B.build_service_account(unquote(name), namespace))
      end
    )
  end

  defp add_rules(pipeline, rules) do
    pipe(
      pipeline,
      quote do
        B.rules(unquote(rules))
      end
    )
  end

  defp add_other_labels(acc_code, metadata, app_name) do
    metadata
    |> Map.get("labels", %{})
    |> Map.drop(@bad_labels)
    |> Enum.reduce(acc_code, fn {key, value}, code ->
      case {key, value} do
        {"app.kubernetes.io/instance", _} -> code
        {"app.kubernetes.io/component", _} -> add_component_label(code, value)
        {_, ^app_name} -> code
        {"app.kubernetes.io/name", _} -> add_component_label(code, value)
        {_, _} -> add_label(code, key, value)
      end
    end)
  end

  defp add_app_labels(pipeline) do
    pipe(
      pipeline,
      quote do
        B.app_labels(@app)
      end
    )
  end

  defp add_component_label(pipeline, label) do
    pipe(
      pipeline,
      quote do
        B.component_label(unquote(label))
      end
    )
  end

  defp add_label(pipeline, label, value) do
    pipe(
      pipeline,
      quote do
        B.label(unquote(label), unquote(value))
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

  defp add_data_from_var(pipeline) do
    pipe(
      pipeline,
      quote do
        B.data(data)
      end
    )
  end

  def starting_code(resource_type) do
    quote do
      B.build_resource(unquote(resource_type))
    end
  end

  defp starting_data do
    quote do
      %{}
    end
  end

  def resource_method_name(resource, app_name) do
    resource_type = resource_type(resource)
    string_resource_type = Atom.to_string(resource_type)

    sanitized_resource_name =
      resource
      |> K8s.Resource.name()
      |> String.downcase()
      |> String.split(~r/[^\w\d]/, trim: true)
      |> Enum.reject(fn v -> v == app_name || String.contains?(string_resource_type, v) end)
      |> Enum.join("_")
      |> then(fn v ->
        case v do
          "" ->
            "main"

          _ ->
            v
        end
      end)

    name = "#{string_resource_type}_#{sanitized_resource_name}"

    String.to_atom(name)
  end

  defp resource_method_from_pipeline(pipeline, method_name) do
    quote do
      def unquote(method_name)(config) do
        namespace = ExampleSettings.namespace(config)
        unquote(pipeline)
      end
    end
  end

  defp resource_method_from_pipeline_and_data(data_pipeline, main_pipeline, method_name) do
    quote do
      def unquote(method_name)(config) do
        namespace = ExampleSettings.namespace(config)
        data = unquote(data_pipeline)
        unquote(main_pipeline)
      end
    end
  end

  defp module(app_name, %{} = methods, includes) when map_size(includes) == 0 do
    quote do
      defmodule KubeResources.ExampleServiceResource do
        alias KubeExt.Builder, as: B
        alias KubeResources.ExampleSettings

        import KubeExt.Yaml

        @app unquote(app_name)

        unquote_splicing(Map.values(methods))
      end
    end
  end

  defp module(app_name, %{} = methods, %{} = includes) do
    include_keywords = Keyword.new(includes)

    quote do
      defmodule KubeResources.ExampleServiceResource do
        use KubeExt.IncludeResource, unquote(include_keywords)

        alias KubeExt.Builder, as: B
        alias KubeResources.ExampleSettings

        import KubeExt.Yaml

        @app unquote(app_name)

        unquote_splicing(Map.values(methods))
      end
    end
  end

  defp crd_file_name(resource) do
    sanitized_name =
      resource |> K8s.Resource.name() |> String.downcase() |> String.replace(~r/[^\w\d]/, "_")

    "#{sanitized_name}.yaml"
  end

  defp crd_include_name(resource),
    do:
      resource
      |> K8s.Resource.name()
      |> to_include_name()

  defp to_include_name(name),
    do:
      name
      |> String.downcase()
      |> String.replace(~r/[^\w\d]/, "_")
      |> String.to_atom()
end
