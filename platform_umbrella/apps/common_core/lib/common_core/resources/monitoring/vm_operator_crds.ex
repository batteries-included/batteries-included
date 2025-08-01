defmodule CommonCore.Resources.VMOperatorCRDs do
  @moduledoc false

  use CommonCore.IncludeResource,
    vlagents_operator_victoriametrics_com: "priv/manifests/vm_operator/vlagents_operator_victoriametrics_com.yaml",
    vlclusters_operator_victoriametrics_com: "priv/manifests/vm_operator/vlclusters_operator_victoriametrics_com.yaml",
    vlogs_operator_victoriametrics_com: "priv/manifests/vm_operator/vlogs_operator_victoriametrics_com.yaml",
    vlsingles_operator_victoriametrics_com: "priv/manifests/vm_operator/vlsingles_operator_victoriametrics_com.yaml",
    vmagents_operator_victoriametrics_com: "priv/manifests/vm_operator/vmagents_operator_victoriametrics_com.yaml",
    vmalertmanagerconfigs_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmalertmanagerconfigs_operator_victoriametrics_com.yaml",
    vmalertmanagers_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmalertmanagers_operator_victoriametrics_com.yaml",
    vmalerts_operator_victoriametrics_com: "priv/manifests/vm_operator/vmalerts_operator_victoriametrics_com.yaml",
    vmanomalies_operator_victoriametrics_com: "priv/manifests/vm_operator/vmanomalies_operator_victoriametrics_com.yaml",
    vmauths_operator_victoriametrics_com: "priv/manifests/vm_operator/vmauths_operator_victoriametrics_com.yaml",
    vmclusters_operator_victoriametrics_com: "priv/manifests/vm_operator/vmclusters_operator_victoriametrics_com.yaml",
    vmnodescrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmnodescrapes_operator_victoriametrics_com.yaml",
    vmpodscrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmpodscrapes_operator_victoriametrics_com.yaml",
    vmprobes_operator_victoriametrics_com: "priv/manifests/vm_operator/vmprobes_operator_victoriametrics_com.yaml",
    vmrules_operator_victoriametrics_com: "priv/manifests/vm_operator/vmrules_operator_victoriametrics_com.yaml",
    vmscrapeconfigs_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmscrapeconfigs_operator_victoriametrics_com.yaml",
    vmservicescrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmservicescrapes_operator_victoriametrics_com.yaml",
    vmsingles_operator_victoriametrics_com: "priv/manifests/vm_operator/vmsingles_operator_victoriametrics_com.yaml",
    vmstaticscrapes_operator_victoriametrics_com:
      "priv/manifests/vm_operator/vmstaticscrapes_operator_victoriametrics_com.yaml",
    vmusers_operator_victoriametrics_com: "priv/manifests/vm_operator/vmusers_operator_victoriametrics_com.yaml"

  use CommonCore.Resources.ResourceGenerator, app_name: "vm_operator_crds"

  multi_resource(:crds_vm_operator) do
    Enum.flat_map(@included_resources, &(&1 |> get_resource() |> YamlElixir.read_all_from_string!()))
  end
end
