defmodule Mix.Tasks.Gen.Resource do
  @shortdoc "Elixir resource skeletons from yaml"

  @moduledoc "The mix task to generate a resource code module from yaml"
  use Mix.Task
  use TypedStruct

  import CommonCore.ApiVersionKind, only: [resource_type: 1]

  alias CommonCore.Resources.Secret
  alias K8s.Resource, as: K8Resource

  @requirements ["app.config"]

  @bad_labels [
    "app.kubernetes.io/managed-by",
    "app.kubernetes.io/version",
    "app.kubernetes.io/created-by",
    "helm.sh/chart",
    "helm.sh/hook-delete-policy",
    "app.kubernetes.io/part-of",
    "operator.tekton.dev/release",
    "chart",
    "release",
    "heritage",
    "version"
  ]

  @max_config_string_size 128

  defmodule ResourceResult do
    @moduledoc false
    typedstruct do
      field :methods, map(), default: %{}
      field :manifests, map(), default: %{}
      field :raw_files, map(), default: %{}
      field :include_paths, map(), default: %{}
    end

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
    write_resource_elixir(result, app_name)
  end

  defp write_resource_elixir(%ResourceResult{} = result, app_name) do
    module = module(app_name, result.include_paths, result.methods)

    resource_path =
      Path.join(File.cwd!(), "apps/common_core/lib/common_core/resources/#{app_name}.ex")

    module_name =
      app_name
      |> String.downcase()
      |> String.split(~r/[^\w]/, trim: true)
      |> Enum.map_join(".", &Macro.camelize/1)

    string_contents =
      module
      |> Macro.to_string()
      |> String.replace(
        "defmodule CommonCore.Resources.ExampleServiceResource",
        "defmodule CommonCore.Resources.#{module_name}"
      )

    File.write!(resource_path, string_contents)
  end

  defp write_manifests(%ResourceResult{} = result, app_name) do
    File.mkdir_p!("apps/common_core/priv/manifests/#{app_name}/")

    result.manifests
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Enum.map(fn {name, contents} -> {crd_path(app_name, name), contents} end)
    |> Enum.each(fn {path, contents} -> File.write!(path, contents) end)
  end

  defp write_raw_files(%ResourceResult{} = result, app_name) do
    File.mkdir_p!("apps/common_core/priv/raw_files/#{app_name}/")

    result.raw_files
    |> Enum.sort_by(fn {name, _} -> name end)
    |> Enum.map(fn {name, contents} -> {raw_file_path(app_name, name), contents} end)
    |> Enum.each(fn {path, contents} -> File.write!(path, contents) end)
  end

  defp crd_path(app_name, crd_filename), do: "apps/common_core/priv/manifests/#{app_name}/#{crd_filename}"

  defp raw_file_path(app_name, filename), do: "apps/common_core/priv/raw_files/#{app_name}/#{filename}"

  defp relative_crd_path(app_name, crd_filename), do: "priv/manifests/#{app_name}/#{crd_filename}"
  defp relative_raw_file_path(app_name, filename), do: "priv/raw_files/#{app_name}/#{filename}"

  defp process_resource(resource, app_name), do: process_resource(resource, resource_type(resource), app_name)

  defp process_resource(resource, nil, _app_name) do
    raise "Unable to find canonical resource_type for { #{inspect(K8Resource.api_version(resource))}, #{inspect(K8Resource.kind(resource))} }"
  end

  defp process_resource(resource, resource_type, app_name)
       when resource_type in [:crd, :aqua_cluster_compliance_report] do
    file_name = manifest_file_name(resource)
    include_name = manifest_include_name(resource)
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

  defp process_resource(resource, :pod_security_policy = resource_type, app_name),
    do: cluster_resource(resource, resource_type, app_name)

  defp process_resource(resource, :validating_webhook_config = resource_type, app_name),
    do: cluster_resource(resource, resource_type, app_name)

  defp process_resource(resource, :mutating_webhook_config = resource_type, app_name),
    do: cluster_resource(resource, resource_type, app_name)

  defp process_resource(%{"spec" => %{"template" => %{"metadata" => %{}}}} = resource, resource_type, app_name) do
    method_name = resource_method_name(resource, app_name)

    spec = resource |> Map.get("spec") |> clean_spec(app_name)

    template = Map.get(spec, "template")

    methods =
      Map.put(
        %{},
        method_name,
        templated_spec_method(Map.drop(resource, ~w(spec)), method_name, resource_type, app_name, spec, template)
      )

    %ResourceResult{
      methods: methods
    }
  end

  defp process_resource(%{"spec" => spec} = resource, resource_type, app_name) do
    method_name = resource_method_name(resource, app_name)

    methods =
      Map.put(
        %{},
        method_name,
        spec_method(Map.drop(resource, ~w(spec)), method_name, resource_type, app_name, spec)
      )

    %ResourceResult{
      methods: methods
    }
  end

  defp process_resource(%{"rules" => rules} = resource, :cluster_role = resource_type, app_name) do
    method_name = resource_method_name(resource, app_name)

    methods =
      Map.put(
        %{},
        method_name,
        cluster_rules_method(resource, method_name, resource_type, app_name, rules)
      )

    %ResourceResult{
      methods: methods
    }
  end

  defp process_resource(%{"rules" => rules} = resource, resource_type, app_name) do
    method_name = resource_method_name(resource, app_name)

    methods =
      Map.put(
        %{},
        method_name,
        rules_method(resource, method_name, resource_type, app_name, rules)
      )

    %ResourceResult{
      methods: methods
    }
  end

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
      |> Map.new()

    # Keep track of where we are writing these things out. This is used
    # to create the CommonCore.IncludeResource line.
    include_paths =
      Map.new(large_data, fn {file_name, _} ->
        {to_include_name(file_name), relative_raw_file_path(app_name, file_name)}
      end)

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
    |> Map.delete("state")
    |> Ymlr.document!()
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
      |> Map.delete("data")
      |> resource_pipeline(:config_map, app_name)
      |> add_data_from_var()

    resource_method_from_pipeline_and_data(data_pipeline, normal_pipeline, method_name)
  end

  defp secret_method(resource, method_name, app_name, small_data, large_data) do
    data_pipeline =
      small_data
      |> data_pipeline(large_data)
      |> add_encode()

    normal_pipeline =
      resource
      |> Map.drop(["data", "stringData"])
      |> resource_pipeline(:secret, app_name)
      |> add_data_from_var()

    resource_method_from_pipeline_and_data(data_pipeline, normal_pipeline, method_name)
  end

  defp templated_spec_method(resource, method_name, resource_type, app_name, spec, template) do
    template_pipeline = template_pipeline(template)

    spec_pipeline =
      spec
      |> clean_spec(app_name)
      |> Map.delete("template")
      |> spec_pipeline()
      |> add_template_from_var()

    normal_pipeline =
      resource
      |> Map.delete("spec")
      |> resource_pipeline(resource_type, app_name)
      |> add_spec_from_var()

    resource_method_from_pipeline_spec_and_template(spec_pipeline, template_pipeline, normal_pipeline, method_name)
  end

  defp spec_method(resource, method_name, resource_type, app_name, spec) do
    spec_pipeline =
      spec
      |> clean_spec(app_name)
      |> spec_pipeline()

    normal_pipeline =
      resource
      |> Map.delete("spec")
      |> resource_pipeline(resource_type, app_name)
      |> add_spec_from_var()

    resource_method_from_pipeline_and_spec(spec_pipeline, normal_pipeline, method_name)
  end

  defp rules_method(resource, method_name, resource_type, app_name, rules) do
    normal_pipeline =
      resource
      |> Map.delete("rules")
      |> resource_pipeline(resource_type, app_name)
      |> add_rules_from_var()

    resource_method_from_pipeline_and_rules(rules, normal_pipeline, method_name)
  end

  defp cluster_rules_method(resource, method_name, resource_type, app_name, rules) do
    normal_pipeline =
      resource
      |> Map.delete("rules")
      |> resource_pipeline(resource_type, app_name)
      |> add_rules_from_var()

    cluster_resource_method_from_pipeline_and_rules(rules, normal_pipeline, method_name)
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
    small_data
    |> Enum.reduce(starting_data(), fn {key, value}, code ->
      add_map_put_key(code, key, value)
    end)
    |> then(fn code_with_small ->
      Enum.reduce(large_data, code_with_small, fn {key, _value}, code ->
        add_map_put_get_resource(code, key, to_include_name(key))
      end)
    end)
  end

  defp spec_pipeline(spec) do
    Enum.reduce(spec, starting_data(), fn {key, value}, code ->
      add_map_put_key(code, key, value)
    end)
  end

  defp template_pipeline(template) do
    template
    |> Enum.reduce(starting_data(), fn {key, value}, code ->
      add_map_put_key(code, key, value)
    end)
    |> add_template_defaults()
  end

  defp yaml_resource_method(method_name, include_name) do
    quote do
      resource(unquote(method_name)) do
        YamlElixir.read_all_from_string!(get_resource(unquote(include_name)))
      end
    end
  end

  defp handle_field("metadata" = _field_name, field_value, acc_code, app_name) do
    name = Map.get(field_value, "name", nil)
    namespace = Map.get(field_value, "namespace", nil)

    acc_code
    |> add_name(name)
    |> add_namespace(namespace)
    |> add_other_labels(field_value, app_name)
  end

  defp handle_field("aggregationRule" = _field_name, field_value, acc_code, _app_name) do
    add_aggregation_rule(acc_code, field_value)
  end

  defp handle_field("rules" = _field_name, field_value, acc_code, _app_name) do
    add_rules(acc_code, field_value)
  end

  defp handle_field("roleRef" = _field_name, %{"kind" => "Role"} = field_value, acc_code, _app_name) do
    add_role_ref(acc_code, Map.get(field_value, "name"))
  end

  defp handle_field("roleRef" = _field_name, %{"kind" => "ClusterRole"} = field_value, acc_code, _app_name) do
    add_cluster_role_ref(acc_code, Map.get(field_value, "name"))
  end

  defp handle_field("subjects" = _field_name, subjects, acc_code, _app_name) do
    Enum.reduce(subjects, acc_code, fn subject, code ->
      add_subject(code, Map.get(subject, "name"), Map.get(subject, "kind"))
    end)
  end

  defp handle_field(field_name, field_value, acc_code, _app_name) do
    add_map_put_key(acc_code, field_name, field_value)
  end

  defp clean_spec(spec, app_name) do
    Map.new(spec, fn {key, value} -> clean_spec_field(key, value, app_name) end)
  end

  defp clean_spec_field("selector", %{"matchLabels" => label_map}, app_name) do
    {"selector", %{"matchLabels" => clean_labels(label_map, app_name)}}
  end

  defp clean_spec_field("selector", %{} = label_map, app_name) do
    {"selector", clean_labels(label_map, app_name)}
  end

  defp clean_spec_field("template", template, app_name) do
    clean_template =
      Map.new(template, fn {key, value} ->
        case {key, value} do
          {"metadata", _} -> {"metadata", clean_template_metadata(value, app_name)}
          {_, _} -> {key, value}
        end
      end)

    {"template", clean_template}
  end

  defp clean_spec_field(key, value, _app_name) do
    {key, value}
  end

  defp clean_labels(label_map, app_name) do
    label_map
    |> Map.drop(@bad_labels)
    |> Map.new(fn {key, value} ->
      case {key, value} do
        {"app", _} -> {"battery/app", app_name}
        {"app.kubernetes.io/instance", _} -> {"battery/app", app_name}
        {"app.kubernetes.io/component", _} -> {"battery/component", value}
        {"app.kubernetes.io/name", _} -> {"battery/component", value}
        {"operator.istio.io/component", _} -> {"battery/component", value}
        {_, _} -> {key, value}
      end
    end)
  end

  defp clean_template_metadata(metadata, app_name) do
    update_in(metadata, ["labels"], fn labels ->
      (labels || %{})
      |> clean_labels(app_name)
      |> Map.put_new("battery/app", app_name)
      |> Map.put("battery/managed", "true")
    end)
  end

  defp pipe(left, right) do
    quote do
      unquote(left) |> unquote(right)
    end
  end

  defp add_template_defaults(pipeline) do
    pipeline
    |> pipe(quote do: B.app_labels(@app_name))
    |> pipe(quote do: B.add_owner(battery))
  end

  defp add_map_put_key(pipeline, key, value) do
    pipe(
      pipeline,
      quote do
        Map.put(unquote(key), unquote(Macro.escape(value)))
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

  defp add_subject(pipeline, name, "ServiceAccount" = _kind) do
    pipe(
      pipeline,
      quote do
        B.subject(B.build_service_account(unquote(name), namespace))
      end
    )
  end

  defp add_subject(pipeline, name, "Group" = _kind) do
    pipe(
      pipeline,
      quote do
        B.subject(B.build_group(unquote(name), namespace))
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

  defp add_aggregation_rule(pipeline, agg_rule_map) do
    pipe(
      pipeline,
      quote do
        B.aggregation_rule(unquote(agg_rule_map))
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

  defp add_component_label(pipeline, label) do
    pipe(
      pipeline,
      quote do
        B.component_labels(unquote(label))
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

  defp add_spec_from_var(pipeline) do
    pipe(
      pipeline,
      quote do
        B.spec(spec)
      end
    )
  end

  defp add_template_from_var(pipeline) do
    pipe(
      pipeline,
      quote do
        B.template(template)
      end
    )
  end

  defp add_rules_from_var(pipeline) do
    pipe(
      pipeline,
      quote do
        B.rules(rules)
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
    |> K8Resource.name()
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
      resource(unquote(method_name), battery, state) do
        namespace = core_namespace(state)
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
      resource(unquote(method_name), battery, state) do
        namespace = core_namespace(state)
        data = unquote(data_pipeline)
        unquote(main_pipeline)
      end
    end
  end

  defp resource_method_from_pipeline_and_spec(spec_pipeline, main_pipeline, method_name) do
    quote do
      resource(unquote(method_name), battery, state) do
        namespace = core_namespace(state)
        spec = unquote(spec_pipeline)
        unquote(main_pipeline)
      end
    end
  end

  defp resource_method_from_pipeline_spec_and_template(spec_pipeline, template_pipeline, main_pipeline, method_name) do
    quote do
      resource(unquote(method_name), battery, state) do
        namespace = core_namespace(state)
        template = unquote(template_pipeline)
        spec = unquote(spec_pipeline)
        unquote(main_pipeline)
      end
    end
  end

  defp resource_method_from_pipeline_and_rules(rules, main_pipeline, method_name) do
    quote do
      resource(unquote(method_name), battery, state) do
        namespace = core_namespace(state)
        rules = unquote(Macro.escape(rules))
        unquote(main_pipeline)
      end
    end
  end

  defp cluster_resource_method_from_pipeline_and_rules(rules, main_pipeline, method_name) do
    quote do
      resource(unquote(method_name)) do
        rules = unquote(Macro.escape(rules))

        unquote(main_pipeline)
      end
    end
  end

  defp module(app_name, includes, methods) when map_size(includes) == 0 do
    quote do
      defmodule CommonCore.Resources.ExampleServiceResource do
        @moduledoc false
        use CommonCore.Resources.ResourceGenerator, app_name: unquote(app_name)

        import CommonCore.StateSummary.Namespaces

        alias CommonCore.Resources.Builder, as: B
        alias CommonCore.Resources.Secret

        unquote_splicing(Map.values(methods))
      end
    end
  end

  defp module(app_name, %{} = includes, methods) do
    include_keywords = includes |> Keyword.new() |> Enum.sort_by(fn {_, path} -> path end)

    sorted_methods =
      methods
      |> Enum.sort_by(fn {name, _contents} -> name end)
      |> Enum.map(fn {_name, contents} -> contents end)

    quote do
      defmodule CommonCore.Resources.ExampleServiceResource do
        @moduledoc false
        use CommonCore.IncludeResource, unquote(include_keywords)
        use CommonCore.Resources.ResourceGenerator, app_name: unquote(app_name)

        import CommonCore.StateSummary.Namespaces

        alias CommonCore.Resources.Builder, as: B
        alias CommonCore.Resources.Secret

        unquote_splicing(sorted_methods)
      end
    end
  end

  defp manifest_file_name(resource) do
    sanitized_name =
      resource |> K8Resource.name() |> String.downcase() |> String.replace(~r/[^\w\d]/, "_")

    "#{sanitized_name}.yaml"
  end

  defp manifest_include_name(resource), do: resource |> K8Resource.name() |> to_include_name()

  defp to_include_name(name), do: name |> String.downcase() |> String.replace(~r/[^\w\d]/, "_") |> String.to_atom()
end
