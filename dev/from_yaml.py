#!/usr/bin/env python
import sys, yaml, json
import re
from collections import Counter

kind_count = Counter()
kind_pattern = re.compile(r"(?<!^)(?=[A-Z])")
colon_pattern = re.compile(r"\"\s*\: ")

# We don't want helm and our things getting into a fight. So don't include any of these
BAD_LABELS = {
    "app.kubernetes.io/managed-by",
    "helm.sh/chart",
    "helm.sh/hook-delete-policy",
    "app.kubernetes.io/version",
    "app.kubernetes.io/name",
    "install.operator.istio.io/owning-resource",
    "operator.knative.dev/release",
    "chart",
    "release",
    "heritage",
}
RENAME_LABELS = {
    "app" : "battery/app",
    "app.kubernetes.io/part-of": "battery/app"
}

BAD_ANNOTATIONS = {
    "helm.sh/hook",
    "helm.sh/chart",
    "helm.sh/hook-delete-policy",
    "checksum/config",
    "checksum/configmap",
    "checksum/secrets",
}


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def get_name(obj):
    if "kind" in obj:
        name = kind_pattern.sub("_", obj["kind"]).lower()
    else:
        name = "unknown"

    current_count = kind_count[name]
    kind_count[name] += 1
    if current_count > 0:
        name = f"{name}_{current_count}"
    return name



def clean_inner(inner, bad_inner_set,renames):
    cleaned = {renames.get(k, k): v for k, v in inner.items() if not k in bad_inner_set}
    return cleaned


def maybe_mutate_value(field_name, value, trigger, bad_inner_set, additions, renames):
    if field_name != trigger:
        return value
    cleaned = clean_inner(value, bad_inner_set,renames)
    for k, v in additions.items():
        cleaned[k] = v
    return cleaned


def recursive_clean(obj, trigger_field_name, bad_inner_fields, additions={}, renames={}):
    if obj is None:
        return None
    elif type(obj) is dict:
        return {
            key: recursive_clean(
                maybe_mutate_value(
                    key, value, trigger_field_name, bad_inner_fields, additions, renames
                ),
                trigger_field_name,
                bad_inner_fields,
                additions=additions,
                renames=renames
            )
            for key, value in obj.items()
            if value != None
        }
    elif type(obj) is list:
        return [
            recursive_clean(o, trigger_field_name, bad_inner_fields, additions, renames=renames)
            for o in obj
        ]
    else:
        return obj


def print_method(name, contents, settings_module_name="TotallyNewSettings"):
    if not name.startswith("cluster_role_") or name.startswith("cluster_role_binding"):
        print(f"def {name}(config) do")
        print(f"namespace = {settings_module_name}.namespace(config)")
        print()
    else:
        print(f"def {name}(_config) do")
    print(f"{contents}")
    print("end")


def print_header(
    module_name="TotallyNewServer", settings_module_name="TotallyNewSettings"
):
    print(f"defmodule KubeResources.{module_name} do")
    print("@moduledoc false")
    print()
    print(f"alias KubeResources.{settings_module_name}")
    print()


def print_materialize(name_json_list):
    print("def materialize(config) do")
    print("%{")
    for idx, value in enumerate(name_json_list):
        name, _ = value
        print(f'"/{idx}/{name}" => {name}(config),')
    print("}")
    print("end")


def print_trailer():
    print()
    print("end")


def print_all_methods(name_json_list, settings_module_name="TotallyNewSettings"):
    for idx, value in enumerate(name_json_list):
        (name, contents) = value
        if idx >= 1:
            print()
        print_method(name, contents, settings_module_name=settings_module_name)


def export_crds_stderr(crds):
    if crds:
        contents = yaml.dump_all(crds, indent=2)
        eprint(contents)


def main(module_name, settings_module_name):
    parsed = yaml.load_all(sys.stdin, Loader=yaml.FullLoader)
    sanitized_labels = [
        recursive_clean(o, "labels", BAD_LABELS, {"battery/managed": "True"}, RENAME_LABELS)
        for o in parsed
        if o
    ]
    sanitized_labels = [
        recursive_clean(o, "selector", {}, {}, RENAME_LABELS)
        for o in sanitized_labels
        if o
    ]
    sanitized_labels = [
        recursive_clean(o, "matchLabels", BAD_LABELS, {"battery/managed": "True"}, RENAME_LABELS)
        for o in sanitized_labels
        if o
    ]
    sanitized_annotations = [
        recursive_clean(o, "annotations", BAD_ANNOTATIONS)
        for o in sanitized_labels
        if o
    ]
    # CRD's are huge and don't need params.
    # Better to import these from an external yaml usually
    no_crds = [
        o
        for o in sanitized_annotations
        if o and "kind" not in o or o["kind"] != "CustomResourceDefinition"
    ]
    only_crds = [
        o
        for o in sanitized_annotations
        if "kind" in o and o["kind"] == "CustomResourceDefinition"
    ]

    # While we are working with the object representation extract
    # the name and the json representation
    named = [(get_name(o), json.dumps(o)) for o in no_crds if o]

    # Don't want json so convert colon seperator to an arrow. In order to try
    # and not get anything other than colons after a field name we accept
    # only directly after double quote.
    to_e_arrow = [(name, colon_pattern.sub('" => ', s)) for (name, s) in named]

    # Open curly brackets are a little less common so be loose and free
    # with how we hack the crap out of this.
    to_e_map = [(name, s.replace("{", "%{")) for (name, s) in to_e_arrow]
    print_header(module_name=module_name, settings_module_name=settings_module_name)
    print_all_methods(to_e_map, settings_module_name=settings_module_name)
    print_materialize(to_e_map)
    print_trailer()

    export_crds_stderr(crds=only_crds)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
