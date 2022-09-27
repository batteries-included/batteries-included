defmodule Mix.Tasks.GenResource do
  @moduledoc "The mix task to generate a resource code module from yaml"

  use Mix.Task

  import KubeExt.Yaml
  import KubeExt.ApiVersionKind, only: [resource_type: 1]
  alias K8s.Resource, as: K8Resource
  alias KubeExt.Secret

  @requirements ["app.config"]

  @bad_labels [
    "app.kubernetes.io/managed-by",
    "app.kubernetes.io/version",
    "app.kubernetes.io/created-by",
    "helm.sh/chart",
    "helm.sh/hook-delete-policy",
    "app.kubernetes.io/part-of",
    "install.operator.istio.io/owning-resource",
    "chart",
    "release",
    "heritage"
  ]

  @max_config_string_size 128

  defmodule ResourceResult do
    defstruct methods: %{},
              manifests: %{},
              raw_files: %{},
              include_paths: %{}

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
    [file_path, app_name, settings_module] = args

    result =
      file_path
      |> YamlElixir.read_all_from_file!()
      |> Enum.reject(&Enum.empty?/1)
      |> Enum.map(fn resource -> process_resource(resource, app_name) end)
      |> Enum.reduce(%ResourceResult{}, &ResourceResult.merge/2)

    write_manifests(result, app_name)
    write_raw_files(result, app_name)
    write_resouce_elixir(result, app_name, settings_module)
  end

  defp write_resouce_elixir(%ResourceResult{} = result, app_name, settings_module) do
    module = module(app_name, result.include_paths, result.methods)

    resource_path =
      Path.join(File.cwd!(), "apps/kube_resources/lib/kube_resources/#{app_name}.ex")

    module_name =
      app_name
      |> String.downcase()
      |> String.split(~r/[^\w]/, trim: true)
      |> Enum.join("_")
      |> Macro.camelize()

    string_contents =
      module
      |> Macro.to_string()
      |> String.replace("alias KubeResources.ExampleSettings", "alias #{settings_module}")
      |> String.replace(
        "defmodule KubeResources.ExampleServiceResource",
        "defmodule KubeResources.#{module_name}"
      )

    File.write!(resource_path, string_contents)
  end

  defp write_manifests(%ResourceResult{} = result, app_name) do
    File.mkdir_p!("apps/kube_resources/priv/manifests/#{app_name}/")

    result.manifests
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Enum.map(fn {name, contents} -> {crd_path(app_name, name), contents} end)
    |> Enum.each(fn {path, contents} -> File.write!(path, contents) end)
  end

  defp write_raw_files(%ResourceResult{} = result, app_name) do
    File.mkdir_p!("apps/kube_resources/priv/raw_files/#{app_name}/")

    result.raw_files
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Enum.map(fn {name, contents} -> {raw_file_path(app_name, name), contents} end)
    |> Enum.each(fn {path, contents} -> File.write!(path, contents) end)
  end

  defp crd_path(app_name, crd_filename),
    do: "apps/kube_resources/priv/manifests/#{app_name}/#{crd_filename}"

  defp raw_file_path(app_name, filename),
    do: "apps/kube_resources/priv/raw_files/#{app_name}/#{filename}"

  defp relative_crd_path(app_name, crd_filename), do: "priv/manifests/#{app_name}/#{crd_filename}"
  defp relative_raw_file_path(app_name, filename), do: "priv/raw_files/#{app_name}/#{filename}"

  defp process_resource(resource, app_name),
    do: process_resource(resource, resource_type(resource), app_name)

  defp process_resource(resource, nil, _app_name) do
    raise "Unable to find canonical resource_type for #{K8Resource.kind(resource)} #{K8Resource.api_version(resource)}"
  end

  defp process_resource(resource, :crd = _resource_type, app_name) do
    file_name = crd_file_name(resource)
    include_name = crd_include_name(resource)
    method_name = resource_method_name(resource, app_name)

    manifests = Map.put(%{}, file_name, to_yaml_contents(resource))
    includes = Map.put(%{}, include_name, relative_crd_path(app_name, file_name))
    methods = Map.put(%{}, method_name, yaml_resource_method(method_name, include_name))

    %ResourceResult{
      manifests: manifests,
      include_paths: includes,
      methods: methods
    }
  end

  defp process_resource(resource, :config_map = _resource_type, app_name) do
    data = Map.get(resource, "data", %{}) || %{}

    {small_data, large_data, include_paths} = split_data_map(data, app_name)

    method_name = resource_method_name(resource, app_name)

    methods =
      Map.put(
        %{},
        method_name,
        config_map_method(resource, method_name, app_name, small_data, large_data)
      )

    %ResourceResult{
      raw_files: large_data,
      include_paths: include_paths,
      methods: methods
    }
  end

  defp process_resource(resource, :secret = _resource_type, app_name) do
    string_data = resource |> Map.get("stringData", %{}) |> then(fn sd -> sd || %{} end)
    data = resource |> Map.get("data", %{}) |> then(fn r -> r || %{} end) |> Secret.decode!()

    {small_data, large_data, include_paths} =
      split_data_map(Map.merge(string_data, data), app_name)

    method_name = resource_method_name(resource, app_name)

    methods =
      Map.put(
        %{},
        method_name,
        secret_method(resource, method_name, app_name, small_data, large_data)
      )

    %ResourceResult{
      raw_files: large_data,
      include_paths: include_paths,
      methods: methods
    }
  end

  defp process_resource(resource, :cluster_role = resource_type, app_name),
    do: cluster_resource(resource, resource_type, app_name)

  defp process_resource(resource, :pod_security_policy = resource_type, app_name),
    do: cluster_resource(resource, resource_type, app_name)

  defp process_resource(resource, :validating_webhook_config = resource_type, app_name),
    do: cluster_resource(resource, resource_type, app_name)

  defp process_resource(resource, :mutating_webhook_config = resource_type, app_name),
    do: cluster_resource(resource, resource_type, app_name)

  defp process_resource(resource, resource_type, app_name) do
    method_name = resource_method_name(resource, app_name)

    method_def = default_method(resource, method_name, resource_type, app_name)
    methods = Map.put(%{}, method_name, method_def)
    %ResourceResult{methods: methods}
  end

  defp split_data_map(data, app_name) do
    # We're going to split the config map into values that are in raw_files and
    # values that are embedded.
    # These are the items that will be include
    large_data =
      data
      |> Enum.filter(fn
        {_key, value} when is_binary(value) ->
          String.length(value) >= @max_config_string_size

        {_key, _value} ->
          false
      end)
      |> Enum.into(%{})

    # Keep track of where we are writing these things out. This is used
    # to create the KubeExt.IncludeResource line.
    include_paths =
      large_data
      |> Enum.map(fn {file_name, _} ->
        {to_include_name(file_name), relative_raw_file_path(app_name, file_name)}
      end)
      |> Enum.into(%{})

    # these are the values that we'll add ourself
    small_data = Map.drop(data, Map.keys(large_data))

    {small_data, large_data, include_paths}
  end

  defp cluster_resource(resource, resource_type, app_name) do
    method_name = resource_method_name(resource, app_name)

    method_def = cluster_scope_method(resource, method_name, resource_type, app_name)
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

  defp cluster_scope_method(resource, method_name, resource_type, app_name) do
    resource
    |> resource_pipeline(resource_type, app_name)
    |> resource_method_from_pipeline_cluster_level(method_name)
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

  defp secret_method(resource, method_name, app_name, small_data, large_data) do
    data_pipeline = small_data |> data_pipeline(large_data) |> add_encode()

    normal_pipeline =
      resource
      |> Map.drop(["data", "stringData"])
      |> resource_pipeline(:secret, app_name)
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
      resource(unquote(method_name)) do
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

  defp handle_field(
         "roleRef" = _field_name,
         %{"kind" => "Role"} = field_value,
         acc_code,
         _app_name
       ) do
    add_role_ref(acc_code, Map.get(field_value, "name"))
  end

  defp handle_field(
         "roleRef" = _field_name,
         %{"kind" => "ClusterRole"} = field_value,
         acc_code,
         _app_name
       ) do
    add_cluster_role_ref(acc_code, Map.get(field_value, "name"))
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

  defp add_map_put_call_with_config(pipeline, key, method_name) do
    pipe(
      pipeline,
      quote do
        Map.put(unquote(key), unquote(method_name)(config))
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

  defp add_cluster_role_ref(pipeline, name) do
    pipe(
      pipeline,
      quote do
        B.role_ref(B.build_cluster_role_ref(unquote(name)))
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

  defp add_encode(pipeline) do
    pipe(
      pipeline,
      quote do
        Secret.encode()
      end
    )
  end

  def resource_method_name(resource, app_name) do
    resource_type = resource_type(resource)
    string_resource_type = Atom.to_string(resource_type)

    sanitized_resource_name = sanitized_resource_name(resource, app_name)

    name = "#{string_resource_type}_#{sanitized_resource_name}"

    String.to_atom(name)
  end

  defp sanitized_resource_name(resource, app_name) do
    resource_type = resource_type(resource)
    string_resource_type = Atom.to_string(resource_type)

    resource
    |> K8s.Resource.name()
    |> then(fn s -> s || "unkown" end)
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
  end

  defp resource_method_from_pipeline(pipeline, method_name) do
    quote do
      resource(unquote(method_name), config) do
        namespace = Settings.namespace(config)
        unquote(pipeline)
      end
    end
  end

  defp resource_method_from_pipeline_cluster_level(pipeline, method_name) do
    quote do
      resource(unquote(method_name)) do
        unquote(pipeline)
      end
    end
  end

  defp resource_method_from_pipeline_and_data(data_pipeline, main_pipeline, method_name) do
    quote do
      resource(unquote(method_name), config) do
        namespace = Settings.namespace(config)
        data = unquote(data_pipeline)
        unquote(main_pipeline)
      end
    end
  end

  defp module(app_name, includes, methods) when map_size(includes) == 0 do
    quote do
      defmodule KubeResources.ExampleServiceResource do
        use KubeExt.ResourceGenerator
        import KubeExt.Yaml

        alias KubeResources.ExampleSettings, as: Settings
        alias KubeExt.Secret

        @app unquote(app_name)

        unquote_splicing(Map.values(methods))
      end
    end
  end

  defp module(app_name, %{} = includes, methods) do
    include_keywords = Keyword.new(includes) |> Enum.sort_by(fn {_, path} -> path end)

    sorted_methods =
      methods
      |> Enum.sort_by(fn {name, _contents} -> name end)
      |> Enum.map(fn {_name, contents} -> contents end)

    quote do
      defmodule KubeResources.ExampleServiceResource do
        use KubeExt.IncludeResource, unquote(include_keywords)
        use KubeExt.ResourceGenerator

        import KubeExt.Yaml

        alias KubeResources.ExampleSettings, as: Settings
        alias KubeExt.Secret

        @app unquote(app_name)

        unquote_splicing(sorted_methods)
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
