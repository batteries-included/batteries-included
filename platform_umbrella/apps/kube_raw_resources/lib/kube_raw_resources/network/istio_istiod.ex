defmodule KubeRawResources.IstioIstiod do
  @moduledoc false

  alias KubeExt.Builder, as: B
  alias KubeRawResources.NetworkSettings

  @istiod_app "istiod"

  @insert_config [
    "# defaultTemplates defines the default template to use for pods that do not explicitly specify a template",
    "defaultTemplates: [sidecar]",
    "policy: enabled",
    "alwaysInjectSelector:",
    "  []",
    "neverInjectSelector:",
    "  []",
    "injectedAnnotations:",
    "template: \"{{ Template_Version_And_Istio_Version_Mismatched_Check_Installation }}\"",
    "templates:",
    "  sidecar: |",
    "    {{- define \"resources\"  }}",
    "      {{- if or (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit`) }}",
    "        {{- if or (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory`) }}",
    "          requests:",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU`) -}}",
    "            cpu: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU` }}\"",
    "            {{ end }}",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory`) -}}",
    "            memory: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory` }}\"",
    "            {{ end }}",
    "        {{- end }}",
    "        {{- if or (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit`) }}",
    "          limits:",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit`) -}}",
    "            cpu: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit` }}\"",
    "            {{ end }}",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit`) -}}",
    "            memory: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit` }}\"",
    "            {{ end }}",
    "        {{- end }}",
    "      {{- else }}",
    "        {{- if .Values.global.proxy.resources }}",
    "          {{ toYaml .Values.global.proxy.resources | indent 6 }}",
    "        {{- end }}",
    "      {{- end }}",
    "    {{- end }}",
    "    {{- $containers := list }}",
    "    {{- range $index, $container := .Spec.Containers }}{{ if not (eq $container.Name \"istio-proxy\") }}{{ $containers = append $containers $container.Name }}{{end}}{{- end}}",
    "    metadata:",
    "      labels:",
    "        security.istio.io/tlsMode: {{ index .ObjectMeta.Labels `security.istio.io/tlsMode` | default \"istio\"  | quote }}",
    "        service.istio.io/canonical-name: {{ index .ObjectMeta.Labels `service.istio.io/canonical-name` | default (index .ObjectMeta.Labels `app.kubernetes.io/name`) | default (index .ObjectMeta.Labels `app`) | default .DeploymentMeta.Name  | quote }}",
    "        service.istio.io/canonical-revision: {{ index .ObjectMeta.Labels `service.istio.io/canonical-revision` | default (index .ObjectMeta.Labels `app.kubernetes.io/version`) | default (index .ObjectMeta.Labels `version`) | default \"latest\"  | quote }}",
    "      annotations: {",
    "        {{- if eq (len $containers) 1 }}",
    "        kubectl.kubernetes.io/default-logs-container: \"{{ index $containers 0 }}\",",
    "        kubectl.kubernetes.io/default-container: \"{{ index $containers 0 }}\",",
    "        {{ end }}",
    "    {{- if .Values.istio_cni.enabled }}",
    "        {{- if not .Values.istio_cni.chained }}",
    "        k8s.v1.cni.cncf.io/networks: '{{ appendMultusNetwork (index .ObjectMeta.Annotations `k8s.v1.cni.cncf.io/networks`) `istio-cni` }}',",
    "        {{- end }}",
    "        sidecar.istio.io/interceptionMode: \"{{ annotation .ObjectMeta `sidecar.istio.io/interceptionMode` .ProxyConfig.InterceptionMode }}\",",
    "        {{ with annotation .ObjectMeta `traffic.sidecar.istio.io/includeOutboundIPRanges` .Values.global.proxy.includeIPRanges }}traffic.sidecar.istio.io/includeOutboundIPRanges: \"{{.}}\",{{ end }}",
    "        {{ with annotation .ObjectMeta `traffic.sidecar.istio.io/excludeOutboundIPRanges` .Values.global.proxy.excludeIPRanges }}traffic.sidecar.istio.io/excludeOutboundIPRanges: \"{{.}}\",{{ end }}",
    "        {{ with annotation .ObjectMeta `traffic.sidecar.istio.io/includeInboundPorts` .Values.global.proxy.includeInboundPorts }}traffic.sidecar.istio.io/includeInboundPorts: \"{{.}}\",{{ end }}",
    "        traffic.sidecar.istio.io/excludeInboundPorts: \"{{ excludeInboundPort (annotation .ObjectMeta `status.sidecar.istio.io/port` .Values.global.proxy.statusPort) (annotation .ObjectMeta `traffic.sidecar.istio.io/excludeInboundPorts` .Values.global.proxy.excludeInboundPorts) }}\",",
    "        {{ if or (isset .ObjectMeta.Annotations `traffic.sidecar.istio.io/includeOutboundPorts`) (ne (valueOrDefault .Values.global.proxy.includeOutboundPorts \"\") \"\") }}",
    "        traffic.sidecar.istio.io/includeOutboundPorts: \"{{ annotation .ObjectMeta `traffic.sidecar.istio.io/includeOutboundPorts` .Values.global.proxy.includeOutboundPorts }}\",",
    "        {{- end }}",
    "        {{ if or (isset .ObjectMeta.Annotations `traffic.sidecar.istio.io/excludeOutboundPorts`) (ne .Values.global.proxy.excludeOutboundPorts \"\") }}",
    "        traffic.sidecar.istio.io/excludeOutboundPorts: \"{{ annotation .ObjectMeta `traffic.sidecar.istio.io/excludeOutboundPorts` .Values.global.proxy.excludeOutboundPorts }}\",",
    "        {{- end }}",
    "        {{ with index .ObjectMeta.Annotations `traffic.sidecar.istio.io/kubevirtInterfaces` }}traffic.sidecar.istio.io/kubevirtInterfaces: \"{{.}}\",{{ end }}",
    "    {{- end }}",
    "      }",
    "    spec:",
    "      {{- $holdProxy := or .ProxyConfig.HoldApplicationUntilProxyStarts.GetValue .Values.global.proxy.holdApplicationUntilProxyStarts }}",
    "      initContainers:",
    "      {{ if ne (annotation .ObjectMeta `sidecar.istio.io/interceptionMode` .ProxyConfig.InterceptionMode) `NONE` }}",
    "      {{ if .Values.istio_cni.enabled -}}",
    "      - name: istio-validation",
    "      {{ else -}}",
    "      - name: istio-init",
    "      {{ end -}}",
    "      {{- if contains \"/\" (annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy_init.image) }}",
    "        image: \"{{ annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy_init.image }}\"",
    "      {{- else }}",
    "        image: \"{{ .ProxyImage }}\"",
    "      {{- end }}",
    "        args:",
    "        - istio-iptables",
    "        - \"-p\"",
    "        - {{ .MeshConfig.ProxyListenPort | default \"15001\" | quote }}",
    "        - \"-z\"",
    "        - \"15006\"",
    "        - \"-u\"",
    "        - \"1337\"",
    "        - \"-m\"",
    "        - \"{{ annotation .ObjectMeta `sidecar.istio.io/interceptionMode` .ProxyConfig.InterceptionMode }}\"",
    "        - \"-i\"",
    "        - \"{{ annotation .ObjectMeta `traffic.sidecar.istio.io/includeOutboundIPRanges` .Values.global.proxy.includeIPRanges }}\"",
    "        - \"-x\"",
    "        - \"{{ annotation .ObjectMeta `traffic.sidecar.istio.io/excludeOutboundIPRanges` .Values.global.proxy.excludeIPRanges }}\"",
    "        - \"-b\"",
    "        - \"{{ annotation .ObjectMeta `traffic.sidecar.istio.io/includeInboundPorts` .Values.global.proxy.includeInboundPorts }}\"",
    "        - \"-d\"",
    "      {{- if excludeInboundPort (annotation .ObjectMeta `status.sidecar.istio.io/port` .Values.global.proxy.statusPort) (annotation .ObjectMeta `traffic.sidecar.istio.io/excludeInboundPorts` .Values.global.proxy.excludeInboundPorts) }}",
    "        - \"15090,15021,{{ excludeInboundPort (annotation .ObjectMeta `status.sidecar.istio.io/port` .Values.global.proxy.statusPort) (annotation .ObjectMeta `traffic.sidecar.istio.io/excludeInboundPorts` .Values.global.proxy.excludeInboundPorts) }}\"",
    "      {{- else }}",
    "        - \"15090,15021\"",
    "      {{- end }}",
    "        {{ if or (isset .ObjectMeta.Annotations `traffic.sidecar.istio.io/includeOutboundPorts`) (ne (valueOrDefault .Values.global.proxy.includeOutboundPorts \"\") \"\") -}}",
    "        - \"-q\"",
    "        - \"{{ annotation .ObjectMeta `traffic.sidecar.istio.io/includeOutboundPorts` .Values.global.proxy.includeOutboundPorts }}\"",
    "        {{ end -}}",
    "        {{ if or (isset .ObjectMeta.Annotations `traffic.sidecar.istio.io/excludeOutboundPorts`) (ne (valueOrDefault .Values.global.proxy.excludeOutboundPorts \"\") \"\") -}}",
    "        - \"-o\"",
    "        - \"{{ annotation .ObjectMeta `traffic.sidecar.istio.io/excludeOutboundPorts` .Values.global.proxy.excludeOutboundPorts }}\"",
    "        {{ end -}}",
    "        {{ if (isset .ObjectMeta.Annotations `traffic.sidecar.istio.io/kubevirtInterfaces`) -}}",
    "        - \"-k\"",
    "        - \"{{ index .ObjectMeta.Annotations `traffic.sidecar.istio.io/kubevirtInterfaces` }}\"",
    "        {{ end -}}",
    "        {{ if .Values.istio_cni.enabled -}}",
    "        - \"--run-validation\"",
    "        - \"--skip-rule-apply\"",
    "        {{ end -}}",
    "        {{with .Values.global.imagePullPolicy }}imagePullPolicy: \"{{.}}\"{{end}}",
    "      {{- if .ProxyConfig.ProxyMetadata }}",
    "        env:",
    "        {{- range $key, $value := .ProxyConfig.ProxyMetadata }}",
    "        - name: {{ $key }}",
    "          value: \"{{ $value }}\"",
    "        {{- end }}",
    "      {{- end }}",
    "        resources:",
    "      {{ template \"resources\" . }}",
    "        securityContext:",
    "          allowPrivilegeEscalation: {{ .Values.global.proxy.privileged }}",
    "          privileged: {{ .Values.global.proxy.privileged }}",
    "          capabilities:",
    "        {{- if not .Values.istio_cni.enabled }}",
    "            add:",
    "            - NET_ADMIN",
    "            - NET_RAW",
    "        {{- end }}",
    "            drop:",
    "            - ALL",
    "        {{- if not .Values.istio_cni.enabled }}",
    "          readOnlyRootFilesystem: false",
    "          runAsGroup: 0",
    "          runAsNonRoot: false",
    "          runAsUser: 0",
    "        {{- else }}",
    "          readOnlyRootFilesystem: true",
    "          runAsGroup: 1337",
    "          runAsUser: 1337",
    "          runAsNonRoot: true",
    "        {{- end }}",
    "        restartPolicy: Always",
    "      {{ end -}}",
    "      {{- if eq (annotation .ObjectMeta `sidecar.istio.io/enableCoreDump` .Values.global.proxy.enableCoreDump) \"true\" }}",
    "      - name: enable-core-dump",
    "        args:",
    "        - -c",
    "        - sysctl -w kernel.core_pattern=/var/lib/istio/data/core.proxy && ulimit -c unlimited",
    "        command:",
    "          - /bin/sh",
    "      {{- if contains \"/\" (annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy_init.image) }}",
    "        image: \"{{ annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy_init.image }}\"",
    "      {{- else }}",
    "        image: \"{{ .ProxyImage }}\"",
    "      {{- end }}",
    "        {{with .Values.global.imagePullPolicy }}imagePullPolicy: \"{{.}}\"{{end}}",
    "        resources:",
    "      {{ template \"resources\" . }}",
    "        securityContext:",
    "          allowPrivilegeEscalation: true",
    "          capabilities:",
    "            add:",
    "            - SYS_ADMIN",
    "            drop:",
    "            - ALL",
    "          privileged: true",
    "          readOnlyRootFilesystem: false",
    "          runAsGroup: 0",
    "          runAsNonRoot: false",
    "          runAsUser: 0",
    "      {{ end }}",
    "      containers:",
    "      - name: istio-proxy",
    "      {{- if contains \"/\" (annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy.image) }}",
    "        image: \"{{ annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy.image }}\"",
    "      {{- else }}",
    "        image: \"{{ .ProxyImage }}\"",
    "      {{- end }}",
    "        ports:",
    "        - containerPort: 15090",
    "          protocol: TCP",
    "          name: http-envoy-prom",
    "        args:",
    "        - proxy",
    "        - sidecar",
    "        - --domain",
    "        - $(POD_NAMESPACE).svc.{{ .Values.global.proxy.clusterDomain }}",
    "        - --proxyLogLevel={{ annotation .ObjectMeta `sidecar.istio.io/logLevel` .Values.global.proxy.logLevel }}",
    "        - --proxyComponentLogLevel={{ annotation .ObjectMeta `sidecar.istio.io/componentLogLevel` .Values.global.proxy.componentLogLevel }}",
    "        - --log_output_level={{ annotation .ObjectMeta `sidecar.istio.io/agentLogLevel` .Values.global.logging.level }}",
    "      {{- if .Values.global.sts.servicePort }}",
    "        - --stsPort={{ .Values.global.sts.servicePort }}",
    "      {{- end }}",
    "      {{- if .Values.global.logAsJson }}",
    "        - --log_as_json",
    "      {{- end }}",
    "      {{- if gt .EstimatedConcurrency 0 }}",
    "        - --concurrency",
    "        - \"{{ .EstimatedConcurrency }}\"",
    "      {{- end -}}",
    "      {{- if .Values.global.proxy.lifecycle }}",
    "        lifecycle:",
    "          {{ toYaml .Values.global.proxy.lifecycle | indent 6 }}",
    "      {{- else if $holdProxy }}",
    "        lifecycle:",
    "          postStart:",
    "            exec:",
    "              command:",
    "              - pilot-agent",
    "              - wait",
    "      {{- end }}",
    "        env:",
    "        {{- if eq (env \"PILOT_ENABLE_INBOUND_PASSTHROUGH\" \"true\") \"false\" }}",
    "        - name: REWRITE_PROBE_LEGACY_LOCALHOST_DESTINATION",
    "          value: \"true\"",
    "        {{- end }}",
    "        - name: JWT_POLICY",
    "          value: {{ .Values.global.jwtPolicy }}",
    "        - name: PILOT_CERT_PROVIDER",
    "          value: {{ .Values.global.pilotCertProvider }}",
    "        - name: CA_ADDR",
    "        {{- if .Values.global.caAddress }}",
    "          value: {{ .Values.global.caAddress }}",
    "        {{- else }}",
    "          value: istiod{{- if not (eq .Values.revision \"\") }}-{{ .Values.revision }}{{- end }}.{{ .Values.global.istioNamespace }}.svc:15012",
    "        {{- end }}",
    "        - name: POD_NAME",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: metadata.name",
    "        - name: POD_NAMESPACE",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: metadata.namespace",
    "        - name: INSTANCE_IP",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: status.podIP",
    "        - name: SERVICE_ACCOUNT",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: spec.serviceAccountName",
    "        - name: HOST_IP",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: status.hostIP",
    "        - name: PROXY_CONFIG",
    "          value: |",
    "                 {{ protoToJSON .ProxyConfig }}",
    "        - name: ISTIO_META_POD_PORTS",
    "          value: |-",
    "            [",
    "            {{- $first := true }}",
    "            {{- range $index1, $c := .Spec.Containers }}",
    "              {{- range $index2, $p := $c.Ports }}",
    "                {{- if (structToJSON $p) }}",
    "                {{if not $first}},{{end}}{{ structToJSON $p }}",
    "                {{- $first = false }}",
    "                {{- end }}",
    "              {{- end}}",
    "            {{- end}}",
    "            ]",
    "        - name: ISTIO_META_APP_CONTAINERS",
    "          value: \"{{ $containers | join \",\" }}\"",
    "        - name: ISTIO_META_CLUSTER_ID",
    "          value: \"{{ valueOrDefault .Values.global.multiCluster.clusterName `Kubernetes` }}\"",
    "        - name: ISTIO_META_INTERCEPTION_MODE",
    "          value: \"{{ or (index .ObjectMeta.Annotations `sidecar.istio.io/interceptionMode`) .ProxyConfig.InterceptionMode.String }}\"",
    "        {{- if .Values.global.network }}",
    "        - name: ISTIO_META_NETWORK",
    "          value: \"{{ .Values.global.network }}\"",
    "        {{- end }}",
    "        {{- if .DeploymentMeta.Name }}",
    "        - name: ISTIO_META_WORKLOAD_NAME",
    "          value: \"{{ .DeploymentMeta.Name }}\"",
    "        {{ end }}",
    "        {{- if and .TypeMeta.APIVersion .DeploymentMeta.Name }}",
    "        - name: ISTIO_META_OWNER",
    "          value: kubernetes://apis/{{ .TypeMeta.APIVersion }}/namespaces/{{ valueOrDefault .DeploymentMeta.Namespace `default` }}/{{ toLower .TypeMeta.Kind}}s/{{ .DeploymentMeta.Name }}",
    "        {{- end}}",
    "        {{- if (isset .ObjectMeta.Annotations `sidecar.istio.io/bootstrapOverride`) }}",
    "        - name: ISTIO_BOOTSTRAP_OVERRIDE",
    "          value: \"/etc/istio/custom-bootstrap/custom_bootstrap.json\"",
    "        {{- end }}",
    "        {{- if .Values.global.meshID }}",
    "        - name: ISTIO_META_MESH_ID",
    "          value: \"{{ .Values.global.meshID }}\"",
    "        {{- else if (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain) }}",
    "        - name: ISTIO_META_MESH_ID",
    "          value: \"{{ (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain) }}\"",
    "        {{- end }}",
    "        {{- with (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain)  }}",
    "        - name: TRUST_DOMAIN",
    "          value: \"{{ . }}\"",
    "        {{- end }}",
    "        {{- if and (eq .Values.global.proxy.tracer \"datadog\") (isset .ObjectMeta.Annotations `apm.datadoghq.com/env`) }}",
    "        {{- range $key, $value := fromJSON (index .ObjectMeta.Annotations `apm.datadoghq.com/env`) }}",
    "        - name: {{ $key }}",
    "          value: \"{{ $value }}\"",
    "        {{- end }}",
    "        {{- end }}",
    "        {{- range $key, $value := .ProxyConfig.ProxyMetadata }}",
    "        - name: {{ $key }}",
    "          value: \"{{ $value }}\"",
    "        {{- end }}",
    "        {{with .Values.global.imagePullPolicy }}imagePullPolicy: \"{{.}}\"{{end}}",
    "        {{ if ne (annotation .ObjectMeta `status.sidecar.istio.io/port` .Values.global.proxy.statusPort) `0` }}",
    "        readinessProbe:",
    "          httpGet:",
    "            path: /healthz/ready",
    "            port: 15021",
    "          initialDelaySeconds: {{ annotation .ObjectMeta `readiness.status.sidecar.istio.io/initialDelaySeconds` .Values.global.proxy.readinessInitialDelaySeconds }}",
    "          periodSeconds: {{ annotation .ObjectMeta `readiness.status.sidecar.istio.io/periodSeconds` .Values.global.proxy.readinessPeriodSeconds }}",
    "          timeoutSeconds: 3",
    "          failureThreshold: {{ annotation .ObjectMeta `readiness.status.sidecar.istio.io/failureThreshold` .Values.global.proxy.readinessFailureThreshold }}",
    "        {{ end -}}",
    "        securityContext:",
    "          {{- if eq (index .ProxyConfig.ProxyMetadata \"IPTABLES_TRACE_LOGGING\") \"true\" }}",
    "          allowPrivilegeEscalation: true",
    "          capabilities:",
    "            add:",
    "            - NET_ADMIN",
    "            drop:",
    "            - ALL",
    "          privileged: true",
    "          readOnlyRootFilesystem: {{ ne (annotation .ObjectMeta `sidecar.istio.io/enableCoreDump` .Values.global.proxy.enableCoreDump) \"true\" }}",
    "          runAsGroup: 1337",
    "          fsGroup: 1337",
    "          runAsNonRoot: false",
    "          runAsUser: 0",
    "          {{- else }}",
    "          allowPrivilegeEscalation: {{ .Values.global.proxy.privileged }}",
    "          capabilities:",
    "            {{ if or (eq (annotation .ObjectMeta `sidecar.istio.io/interceptionMode` .ProxyConfig.InterceptionMode) `TPROXY`) (eq (annotation .ObjectMeta `sidecar.istio.io/capNetBindService` .Values.global.proxy.capNetBindService) `true`) -}}",
    "            add:",
    "            {{ if eq (annotation .ObjectMeta `sidecar.istio.io/interceptionMode` .ProxyConfig.InterceptionMode) `TPROXY` -}}",
    "            - NET_ADMIN",
    "            {{- end }}",
    "            {{ if eq (annotation .ObjectMeta `sidecar.istio.io/capNetBindService` .Values.global.proxy.capNetBindService) `true` -}}",
    "            - NET_BIND_SERVICE",
    "            {{- end }}",
    "            {{- end }}",
    "            drop:",
    "            - ALL",
    "          privileged: {{ .Values.global.proxy.privileged }}",
    "          readOnlyRootFilesystem: {{ ne (annotation .ObjectMeta `sidecar.istio.io/enableCoreDump` .Values.global.proxy.enableCoreDump) \"true\" }}",
    "          runAsGroup: 1337",
    "          fsGroup: 1337",
    "          {{ if or (eq (annotation .ObjectMeta `sidecar.istio.io/interceptionMode` .ProxyConfig.InterceptionMode) `TPROXY`) (eq (annotation .ObjectMeta `sidecar.istio.io/capNetBindService` .Values.global.proxy.capNetBindService) `true`) -}}",
    "          runAsNonRoot: false",
    "          runAsUser: 0",
    "          {{- else -}}",
    "          runAsNonRoot: true",
    "          runAsUser: 1337",
    "          {{- end }}",
    "          {{- end }}",
    "        resources:",
    "      {{ template \"resources\" . }}",
    "        volumeMounts:",
    "        {{- if eq .Values.global.caName \"GkeWorkloadCertificate\" }}",
    "        - name: gke-workload-certificate",
    "          mountPath: /var/run/secrets/workload-spiffe-credentials",
    "          readOnly: true",
    "        {{- end }}",
    "        {{- if eq .Values.global.pilotCertProvider \"istiod\" }}",
    "        - mountPath: /var/run/secrets/istio",
    "          name: istiod-ca-cert",
    "        {{- end }}",
    "        - mountPath: /var/lib/istio/data",
    "          name: istio-data",
    "        {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/bootstrapOverride`) }}",
    "        - mountPath: /etc/istio/custom-bootstrap",
    "          name: custom-bootstrap-volume",
    "        {{- end }}",
    "        # SDS channel between istioagent and Envoy",
    "        - mountPath: /etc/istio/proxy",
    "          name: istio-envoy",
    "        {{- if eq .Values.global.jwtPolicy \"third-party-jwt\" }}",
    "        - mountPath: /var/run/secrets/tokens",
    "          name: istio-token",
    "        {{- end }}",
    "        {{- if .Values.global.mountMtlsCerts }}",
    "        # Use the key and cert mounted to /etc/certs/ for the in-cluster mTLS communications.",
    "        - mountPath: /etc/certs/",
    "          name: istio-certs",
    "          readOnly: true",
    "        {{- end }}",
    "        - name: istio-podinfo",
    "          mountPath: /etc/istio/pod",
    "         {{- if and (eq .Values.global.proxy.tracer \"lightstep\") .ProxyConfig.GetTracing.GetTlsSettings }}",
    "        - mountPath: {{ directory .ProxyConfig.GetTracing.GetTlsSettings.GetCaCertificates }}",
    "          name: lightstep-certs",
    "          readOnly: true",
    "        {{- end }}",
    "          {{- if isset .ObjectMeta.Annotations `sidecar.istio.io/userVolumeMount` }}",
    "          {{ range $index, $value := fromJSON (index .ObjectMeta.Annotations `sidecar.istio.io/userVolumeMount`) }}",
    "        - name: \"{{  $index }}\"",
    "          {{ toYaml $value | indent 6 }}",
    "          {{ end }}",
    "          {{- end }}",
    "      volumes:",
    "      {{- if eq .Values.global.caName \"GkeWorkloadCertificate\" }}",
    "      - name: gke-workload-certificate",
    "        csi:",
    "          driver: workloadcertificates.security.cloud.google.com",
    "      {{- end }}",
    "      {{- if (isset .ObjectMeta.Annotations `sidecar.istio.io/bootstrapOverride`) }}",
    "      - name: custom-bootstrap-volume",
    "        configMap:",
    "          name: {{ annotation .ObjectMeta `sidecar.istio.io/bootstrapOverride` \"\" }}",
    "      {{- end }}",
    "      # SDS channel between istioagent and Envoy",
    "      - emptyDir:",
    "          medium: Memory",
    "        name: istio-envoy",
    "      - name: istio-data",
    "        emptyDir: {}",
    "      - name: istio-podinfo",
    "        downwardAPI:",
    "          items:",
    "            - path: \"labels\"",
    "              fieldRef:",
    "                fieldPath: metadata.labels",
    "            - path: \"annotations\"",
    "              fieldRef:",
    "                fieldPath: metadata.annotations",
    "      {{- if eq .Values.global.jwtPolicy \"third-party-jwt\" }}",
    "      - name: istio-token",
    "        projected:",
    "          sources:",
    "          - serviceAccountToken:",
    "              path: istio-token",
    "              expirationSeconds: 43200",
    "              audience: {{ .Values.global.sds.token.aud }}",
    "      {{- end }}",
    "      {{- if eq .Values.global.pilotCertProvider \"istiod\" }}",
    "      - name: istiod-ca-cert",
    "        configMap:",
    "          name: istio-ca-root-cert",
    "      {{- end }}",
    "      {{- if .Values.global.mountMtlsCerts }}",
    "      # Use the key and cert mounted to /etc/certs/ for the in-cluster mTLS communications.",
    "      - name: istio-certs",
    "        secret:",
    "          optional: true",
    "          {{ if eq .Spec.ServiceAccountName \"\" }}",
    "          secretName: istio.default",
    "          {{ else -}}",
    "          secretName: {{  printf \"istio.%s\" .Spec.ServiceAccountName }}",
    "          {{  end -}}",
    "      {{- end }}",
    "        {{- if isset .ObjectMeta.Annotations `sidecar.istio.io/userVolume` }}",
    "        {{range $index, $value := fromJSON (index .ObjectMeta.Annotations `sidecar.istio.io/userVolume`) }}",
    "      - name: \"{{ $index }}\"",
    "        {{ toYaml $value | indent 4 }}",
    "        {{ end }}",
    "        {{ end }}",
    "      {{- if and (eq .Values.global.proxy.tracer \"lightstep\") .ProxyConfig.GetTracing.GetTlsSettings }}",
    "      - name: lightstep-certs",
    "        secret:",
    "          optional: true",
    "          secretName: lightstep.cacert",
    "      {{- end }}",
    "      {{- if .Values.global.imagePullSecrets }}",
    "      imagePullSecrets:",
    "        {{- range .Values.global.imagePullSecrets }}",
    "        - name: {{ . }}",
    "        {{- end }}",
    "      {{- end }}",
    "      {{- if eq (env \"ENABLE_LEGACY_FSGROUP_INJECTION\" \"true\") \"true\" }}",
    "      securityContext:",
    "        fsGroup: 1337",
    "      {{- end }}",
    "  gateway: |",
    "    {{- $containers := list }}",
    "    {{- range $index, $container := .Spec.Containers }}{{ if not (eq $container.Name \"istio-proxy\") }}{{ $containers = append $containers $container.Name }}{{end}}{{- end}}",
    "    metadata:",
    "      labels:",
    "        service.istio.io/canonical-name: {{ index .ObjectMeta.Labels `service.istio.io/canonical-name` | default (index .ObjectMeta.Labels `app.kubernetes.io/name`) | default (index .ObjectMeta.Labels `app`) | default .DeploymentMeta.Name  | quote }}",
    "        service.istio.io/canonical-revision: {{ index .ObjectMeta.Labels `service.istio.io/canonical-revision` | default (index .ObjectMeta.Labels `app.kubernetes.io/version`) | default (index .ObjectMeta.Labels `version`) | default \"latest\"  | quote }}",
    "        istio.io/rev: {{ .Revision | default \"default\" | quote }}",
    "      annotations: {",
    "        {{- if eq (len $containers) 1 }}",
    "        kubectl.kubernetes.io/default-logs-container: \"{{ index $containers 0 }}\",",
    "        kubectl.kubernetes.io/default-container: \"{{ index $containers 0 }}\",",
    "        {{ end }}",
    "      }",
    "    spec:",
    "      containers:",
    "      - name: istio-proxy",
    "      {{- if contains \"/\" .Values.global.proxy.image }}",
    "        image: \"{{ annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy.image }}\"",
    "      {{- else }}",
    "        image: \"{{ .ProxyImage }}\"",
    "      {{- end }}",
    "        ports:",
    "        - containerPort: 15090",
    "          protocol: TCP",
    "          name: http-envoy-prom",
    "        args:",
    "        - proxy",
    "        - router",
    "        - --domain",
    "        - $(POD_NAMESPACE).svc.{{ .Values.global.proxy.clusterDomain }}",
    "        - --proxyLogLevel={{ annotation .ObjectMeta `sidecar.istio.io/logLevel` .Values.global.proxy.logLevel }}",
    "        - --proxyComponentLogLevel={{ annotation .ObjectMeta `sidecar.istio.io/componentLogLevel` .Values.global.proxy.componentLogLevel }}",
    "        - --log_output_level={{ annotation .ObjectMeta `sidecar.istio.io/agentLogLevel` .Values.global.logging.level }}",
    "      {{- if .Values.global.sts.servicePort }}",
    "        - --stsPort={{ .Values.global.sts.servicePort }}",
    "      {{- end }}",
    "      {{- if .Values.global.logAsJson }}",
    "        - --log_as_json",
    "      {{- end }}",
    "      {{- if .Values.global.proxy.lifecycle }}",
    "        lifecycle:",
    "          {{ toYaml .Values.global.proxy.lifecycle | indent 6 }}",
    "      {{- end }}",
    "        env:",
    "        - name: JWT_POLICY",
    "          value: {{ .Values.global.jwtPolicy }}",
    "        - name: PILOT_CERT_PROVIDER",
    "          value: {{ .Values.global.pilotCertProvider }}",
    "        - name: CA_ADDR",
    "        {{- if .Values.global.caAddress }}",
    "          value: {{ .Values.global.caAddress }}",
    "        {{- else }}",
    "          value: istiod{{- if not (eq .Values.revision \"\") }}-{{ .Values.revision }}{{- end }}.{{ .Values.global.istioNamespace }}.svc:15012",
    "        {{- end }}",
    "        - name: POD_NAME",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: metadata.name",
    "        - name: POD_NAMESPACE",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: metadata.namespace",
    "        - name: INSTANCE_IP",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: status.podIP",
    "        - name: SERVICE_ACCOUNT",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: spec.serviceAccountName",
    "        - name: HOST_IP",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: status.hostIP",
    "        - name: PROXY_CONFIG",
    "          value: |",
    "                 {{ protoToJSON .ProxyConfig }}",
    "        - name: ISTIO_META_POD_PORTS",
    "          value: |-",
    "            [",
    "            {{- $first := true }}",
    "            {{- range $index1, $c := .Spec.Containers }}",
    "              {{- range $index2, $p := $c.Ports }}",
    "                {{- if (structToJSON $p) }}",
    "                {{if not $first}},{{end}}{{ structToJSON $p }}",
    "                {{- $first = false }}",
    "                {{- end }}",
    "              {{- end}}",
    "            {{- end}}",
    "            ]",
    "        - name: ISTIO_META_APP_CONTAINERS",
    "          value: \"{{ $containers | join \",\" }}\"",
    "        - name: ISTIO_META_CLUSTER_ID",
    "          value: \"{{ valueOrDefault .Values.global.multiCluster.clusterName `Kubernetes` }}\"",
    "        - name: ISTIO_META_INTERCEPTION_MODE",
    "          value: \"{{ .ProxyConfig.InterceptionMode.String }}\"",
    "        {{- if .Values.global.network }}",
    "        - name: ISTIO_META_NETWORK",
    "          value: \"{{ .Values.global.network }}\"",
    "        {{- end }}",
    "        {{- if .DeploymentMeta.Name }}",
    "        - name: ISTIO_META_WORKLOAD_NAME",
    "          value: \"{{ .DeploymentMeta.Name }}\"",
    "        {{ end }}",
    "        {{- if and .TypeMeta.APIVersion .DeploymentMeta.Name }}",
    "        - name: ISTIO_META_OWNER",
    "          value: kubernetes://apis/{{ .TypeMeta.APIVersion }}/namespaces/{{ valueOrDefault .DeploymentMeta.Namespace `default` }}/{{ toLower .TypeMeta.Kind}}s/{{ .DeploymentMeta.Name }}",
    "        {{- end}}",
    "        {{- if .Values.global.meshID }}",
    "        - name: ISTIO_META_MESH_ID",
    "          value: \"{{ .Values.global.meshID }}\"",
    "        {{- else if (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain) }}",
    "        - name: ISTIO_META_MESH_ID",
    "          value: \"{{ (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain) }}\"",
    "        {{- end }}",
    "        {{- with (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain)  }}",
    "        - name: TRUST_DOMAIN",
    "          value: \"{{ . }}\"",
    "        {{- end }}",
    "        {{- range $key, $value := .ProxyConfig.ProxyMetadata }}",
    "        - name: {{ $key }}",
    "          value: \"{{ $value }}\"",
    "        {{- end }}",
    "        {{with .Values.global.imagePullPolicy }}imagePullPolicy: \"{{.}}\"{{end}}",
    "        readinessProbe:",
    "          httpGet:",
    "            path: /healthz/ready",
    "            port: 15021",
    "          initialDelaySeconds: {{.Values.global.proxy.readinessInitialDelaySeconds }}",
    "          periodSeconds: {{ .Values.global.proxy.readinessPeriodSeconds }}",
    "          timeoutSeconds: 3",
    "          failureThreshold: {{ .Values.global.proxy.readinessFailureThreshold }}",
    "        volumeMounts:",
    "        {{- if eq .Values.global.caName \"GkeWorkloadCertificate\" }}",
    "        - name: gke-workload-certificate",
    "          mountPath: /var/run/secrets/workload-spiffe-credentials",
    "          readOnly: true",
    "        {{- end }}",
    "        {{- if eq .Values.global.pilotCertProvider \"istiod\" }}",
    "        - mountPath: /var/run/secrets/istio",
    "          name: istiod-ca-cert",
    "        {{- end }}",
    "        - mountPath: /var/lib/istio/data",
    "          name: istio-data",
    "        # SDS channel between istioagent and Envoy",
    "        - mountPath: /etc/istio/proxy",
    "          name: istio-envoy",
    "        {{- if eq .Values.global.jwtPolicy \"third-party-jwt\" }}",
    "        - mountPath: /var/run/secrets/tokens",
    "          name: istio-token",
    "        {{- end }}",
    "        {{- if .Values.global.mountMtlsCerts }}",
    "        # Use the key and cert mounted to /etc/certs/ for the in-cluster mTLS communications.",
    "        - mountPath: /etc/certs/",
    "          name: istio-certs",
    "          readOnly: true",
    "        {{- end }}",
    "        - name: istio-podinfo",
    "          mountPath: /etc/istio/pod",
    "      volumes:",
    "      {{- if eq .Values.global.caName \"GkeWorkloadCertificate\" }}",
    "      - name: gke-workload-certificate",
    "        csi:",
    "          driver: workloadcertificates.security.cloud.google.com",
    "      {{- end }}",
    "      # SDS channel between istioagent and Envoy",
    "      - emptyDir:",
    "          medium: Memory",
    "        name: istio-envoy",
    "      - name: istio-data",
    "        emptyDir: {}",
    "      - name: istio-podinfo",
    "        downwardAPI:",
    "          items:",
    "            - path: \"labels\"",
    "              fieldRef:",
    "                fieldPath: metadata.labels",
    "            - path: \"annotations\"",
    "              fieldRef:",
    "                fieldPath: metadata.annotations",
    "      {{- if eq .Values.global.jwtPolicy \"third-party-jwt\" }}",
    "      - name: istio-token",
    "        projected:",
    "          sources:",
    "          - serviceAccountToken:",
    "              path: istio-token",
    "              expirationSeconds: 43200",
    "              audience: {{ .Values.global.sds.token.aud }}",
    "      {{- end }}",
    "      {{- if eq .Values.global.pilotCertProvider \"istiod\" }}",
    "      - name: istiod-ca-cert",
    "        configMap:",
    "          name: istio-ca-root-cert",
    "      {{- end }}",
    "      {{- if .Values.global.mountMtlsCerts }}",
    "      # Use the key and cert mounted to /etc/certs/ for the in-cluster mTLS communications.",
    "      - name: istio-certs",
    "        secret:",
    "          optional: true",
    "          {{ if eq .Spec.ServiceAccountName \"\" }}",
    "          secretName: istio.default",
    "          {{ else -}}",
    "          secretName: {{  printf \"istio.%s\" .Spec.ServiceAccountName }}",
    "          {{  end -}}",
    "      {{- end }}",
    "      {{- if .Values.global.imagePullSecrets }}",
    "      imagePullSecrets:",
    "        {{- range .Values.global.imagePullSecrets }}",
    "        - name: {{ . }}",
    "        {{- end }}",
    "      {{- end }}",
    "      {{- if eq (env \"ENABLE_LEGACY_FSGROUP_INJECTION\" \"true\") \"true\" }}",
    "      securityContext:",
    "        fsGroup: 1337",
    "      {{- end }}",
    "  grpc-simple: |",
    "    metadata:",
    "      sidecar.istio.io/rewriteAppHTTPProbers: \"false\"",
    "    spec:",
    "      initContainers:",
    "        - name: grpc-bootstrap-init",
    "          image: busybox:1.28",
    "          volumeMounts:",
    "            - mountPath: /var/lib/grpc/data/",
    "              name: grpc-io-proxyless-bootstrap",
    "          env:",
    "            - name: INSTANCE_IP",
    "              valueFrom:",
    "                fieldRef:",
    "                  fieldPath: status.podIP",
    "            - name: POD_NAME",
    "              valueFrom:",
    "                fieldRef:",
    "                  fieldPath: metadata.name",
    "            - name: POD_NAMESPACE",
    "              valueFrom:",
    "                fieldRef:",
    "                  fieldPath: metadata.namespace",
    "            - name: ISTIO_NAMESPACE",
    "              value: |",
    "                 {{ .Values.global.istioNamespace }}",
    "          command:",
    "            - sh",
    "            - \"-c\"",
    "            - |-",
    "              NODE_ID=\"sidecar~${INSTANCE_IP}~${POD_NAME}.${POD_NAMESPACE}~cluster.local\"",
    "              SERVER_URI=\"dns:///istiod.${ISTIO_NAMESPACE}.svc:15010\"",
    "              echo '",
    "              {",
    "                \"xds_servers\": [",
    "                  {",
    "                    \"server_uri\": \"'${SERVER_URI}'\",",
    "                    \"channel_creds\": [{\"type\": \"insecure\"}],",
    "                    \"server_features\" : [\"xds_v3\"]",
    "                  }",
    "                ],",
    "                \"node\": {",
    "                  \"id\": \"'${NODE_ID}'\",",
    "                  \"metadata\": {",
    "                    \"GENERATOR\": \"grpc\"",
    "                  }",
    "                }",
    "              }' > /var/lib/grpc/data/bootstrap.json",
    "      containers:",
    "      {{- range $index, $container := .Spec.Containers }}",
    "      - name: {{ $container.Name }}",
    "        env:",
    "          - name: GRPC_XDS_BOOTSTRAP",
    "            value: /var/lib/grpc/data/bootstrap.json",
    "          - name: GRPC_GO_LOG_VERBOSITY_LEVEL",
    "            value: \"99\"",
    "          - name: GRPC_GO_LOG_SEVERITY_LEVEL",
    "            value: info",
    "        volumeMounts:",
    "          - mountPath: /var/lib/grpc/data/",
    "            name: grpc-io-proxyless-bootstrap",
    "      {{- end }}",
    "      volumes:",
    "        - name: grpc-io-proxyless-bootstrap",
    "          emptyDir: {}",
    "  grpc-agent: |",
    "    {{- $containers := list }}",
    "    {{- range $index, $container := .Spec.Containers }}{{ if not (eq $container.Name \"istio-proxy\") }}{{ $containers = append $containers $container.Name }}{{end}}{{- end}}",
    "    metadata:",
    "      labels:",
    "        service.istio.io/canonical-name: {{ index .ObjectMeta.Labels `service.istio.io/canonical-name` | default (index .ObjectMeta.Labels `app.kubernetes.io/name`) | default (index .ObjectMeta.Labels `app`) | default .DeploymentMeta.Name  | quote }}",
    "        service.istio.io/canonical-revision: {{ index .ObjectMeta.Labels `service.istio.io/canonical-revision` | default (index .ObjectMeta.Labels `app.kubernetes.io/version`) | default (index .ObjectMeta.Labels `version`) | default \"latest\"  | quote }}",
    "      annotations: {",
    "        {{- if eq (len $containers) 1 }}",
    "        kubectl.kubernetes.io/default-logs-container: \"{{ index $containers 0 }}\",",
    "        kubectl.kubernetes.io/default-container: \"{{ index $containers 0 }}\",",
    "        {{ end }}",
    "        sidecar.istio.io/rewriteAppHTTPProbers: \"false\",",
    "      }",
    "    spec:",
    "      containers:",
    "      {{- range $index, $container := .Spec.Containers  }}",
    "      {{ if not (eq $container.Name \"istio-proxy\") }}",
    "      - name: {{ $container.Name }}",
    "        env:",
    "        - name: \"GRPC_XDS_EXPERIMENTAL_SECURITY_SUPPORT\"",
    "          value: \"true\"",
    "        - name: \"GRPC_XDS_BOOTSTRAP\"",
    "          value: \"/etc/istio/proxy/grpc-bootstrap.json\"",
    "        volumeMounts:",
    "        - mountPath: /var/lib/istio/data",
    "          name: istio-data",
    "        # UDS channel between istioagent and gRPC client for XDS/SDS",
    "        - mountPath: /etc/istio/proxy",
    "          name: istio-xds",
    "      {{- end }}",
    "      {{- end }}",
    "      - name: istio-proxy",
    "      {{- if contains \"/\" (annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy.image) }}",
    "        image: \"{{ annotation .ObjectMeta `sidecar.istio.io/proxyImage` .Values.global.proxy.image }}\"",
    "      {{- else }}",
    "        image: \"{{ .ProxyImage }}\"",
    "      {{- end }}",
    "        args:",
    "        - proxy",
    "        - sidecar",
    "        - --domain",
    "        - $(POD_NAMESPACE).svc.{{ .Values.global.proxy.clusterDomain }}",
    "        - --log_output_level={{ annotation .ObjectMeta `sidecar.istio.io/agentLogLevel` .Values.global.logging.level }}",
    "      {{- if .Values.global.sts.servicePort }}",
    "        - --stsPort={{ .Values.global.sts.servicePort }}",
    "      {{- end }}",
    "      {{- if .Values.global.logAsJson }}",
    "        - --log_as_json",
    "      {{- end }}",
    "        env:",
    "        - name: ISTIO_META_GENERATOR",
    "          value: grpc",
    "        - name: OUTPUT_CERTS",
    "          value: /var/lib/istio/data",
    "        {{- if eq (env \"PILOT_ENABLE_INBOUND_PASSTHROUGH\" \"true\") \"false\" }}",
    "        - name: REWRITE_PROBE_LEGACY_LOCALHOST_DESTINATION",
    "          value: \"true\"",
    "        {{- end }}",
    "        - name: JWT_POLICY",
    "          value: {{ .Values.global.jwtPolicy }}",
    "        - name: PILOT_CERT_PROVIDER",
    "          value: {{ .Values.global.pilotCertProvider }}",
    "        - name: CA_ADDR",
    "        {{- if .Values.global.caAddress }}",
    "          value: {{ .Values.global.caAddress }}",
    "        {{- else }}",
    "          value: istiod{{- if not (eq .Values.revision \"\") }}-{{ .Values.revision }}{{- end }}.{{ .Values.global.istioNamespace }}.svc:15012",
    "        {{- end }}",
    "        - name: POD_NAME",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: metadata.name",
    "        - name: POD_NAMESPACE",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: metadata.namespace",
    "        - name: INSTANCE_IP",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: status.podIP",
    "        - name: SERVICE_ACCOUNT",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: spec.serviceAccountName",
    "        - name: HOST_IP",
    "          valueFrom:",
    "            fieldRef:",
    "              fieldPath: status.hostIP",
    "        - name: PROXY_CONFIG",
    "          value: |",
    "                 {{ protoToJSON .ProxyConfig }}",
    "        - name: ISTIO_META_POD_PORTS",
    "          value: |-",
    "            [",
    "            {{- $first := true }}",
    "            {{- range $index1, $c := .Spec.Containers }}",
    "              {{- range $index2, $p := $c.Ports }}",
    "                {{- if (structToJSON $p) }}",
    "                {{if not $first}},{{end}}{{ structToJSON $p }}",
    "                {{- $first = false }}",
    "                {{- end }}",
    "              {{- end}}",
    "            {{- end}}",
    "            ]",
    "        - name: ISTIO_META_APP_CONTAINERS",
    "          value: \"{{ $containers | join \",\" }}\"",
    "        - name: ISTIO_META_CLUSTER_ID",
    "          value: \"{{ valueOrDefault .Values.global.multiCluster.clusterName `Kubernetes` }}\"",
    "        - name: ISTIO_META_INTERCEPTION_MODE",
    "          value: \"{{ or (index .ObjectMeta.Annotations `sidecar.istio.io/interceptionMode`) .ProxyConfig.InterceptionMode.String }}\"",
    "        {{- if .Values.global.network }}",
    "        - name: ISTIO_META_NETWORK",
    "          value: \"{{ .Values.global.network }}\"",
    "        {{- end }}",
    "        {{- if .DeploymentMeta.Name }}",
    "        - name: ISTIO_META_WORKLOAD_NAME",
    "          value: \"{{ .DeploymentMeta.Name }}\"",
    "        {{ end }}",
    "        {{- if and .TypeMeta.APIVersion .DeploymentMeta.Name }}",
    "        - name: ISTIO_META_OWNER",
    "          value: kubernetes://apis/{{ .TypeMeta.APIVersion }}/namespaces/{{ valueOrDefault .DeploymentMeta.Namespace `default` }}/{{ toLower .TypeMeta.Kind}}s/{{ .DeploymentMeta.Name }}",
    "        {{- end}}",
    "        {{- if .Values.global.meshID }}",
    "        - name: ISTIO_META_MESH_ID",
    "          value: \"{{ .Values.global.meshID }}\"",
    "        {{- else if (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain) }}",
    "        - name: ISTIO_META_MESH_ID",
    "          value: \"{{ (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain) }}\"",
    "        {{- end }}",
    "        {{- with (valueOrDefault .MeshConfig.TrustDomain .Values.global.trustDomain)  }}",
    "        - name: TRUST_DOMAIN",
    "          value: \"{{ . }}\"",
    "        {{- end }}",
    "        {{- range $key, $value := .ProxyConfig.ProxyMetadata }}",
    "        - name: {{ $key }}",
    "          value: \"{{ $value }}\"",
    "        {{- end }}",
    "        # grpc uses xds:/// to resolve – no need to resolve VIP",
    "        - name: ISTIO_META_DNS_CAPTURE",
    "          value: \"false\"",
    "        - name: DISABLE_ENVOY",
    "          value: \"true\"",
    "        {{with .Values.global.imagePullPolicy }}imagePullPolicy: \"{{.}}\"{{end}}",
    "        {{ if ne (annotation .ObjectMeta `status.sidecar.istio.io/port` .Values.global.proxy.statusPort) `0` }}",
    "        readinessProbe:",
    "          httpGet:",
    "            path: /healthz/ready",
    "            port: {{ .Values.global.proxy.statusPort }}",
    "          initialDelaySeconds: {{ annotation .ObjectMeta `readiness.status.sidecar.istio.io/initialDelaySeconds` .Values.global.proxy.readinessInitialDelaySeconds }}",
    "          periodSeconds: {{ annotation .ObjectMeta `readiness.status.sidecar.istio.io/periodSeconds` .Values.global.proxy.readinessPeriodSeconds }}",
    "          timeoutSeconds: 3",
    "          failureThreshold: {{ annotation .ObjectMeta `readiness.status.sidecar.istio.io/failureThreshold` .Values.global.proxy.readinessFailureThreshold }}",
    "        {{ end -}}",
    "        resources:",
    "      {{- if or (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit`) }}",
    "        {{- if or (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory`) }}",
    "          requests:",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU`) -}}",
    "            cpu: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyCPU` }}\"",
    "            {{ end }}",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory`) -}}",
    "            memory: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyMemory` }}\"",
    "            {{ end }}",
    "        {{- end }}",
    "        {{- if or (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit`) (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit`) }}",
    "          limits:",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit`) -}}",
    "            cpu: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyCPULimit` }}\"",
    "            {{ end }}",
    "            {{ if (isset .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit`) -}}",
    "            memory: \"{{ index .ObjectMeta.Annotations `sidecar.istio.io/proxyMemoryLimit` }}\"",
    "            {{ end }}",
    "        {{- end }}",
    "      {{- else }}",
    "        {{- if .Values.global.proxy.resources }}",
    "          {{ toYaml .Values.global.proxy.resources | indent 6 }}",
    "        {{- end }}",
    "      {{- end }}",
    "        volumeMounts:",
    "        {{- if eq .Values.global.pilotCertProvider \"istiod\" }}",
    "        - mountPath: /var/run/secrets/istio",
    "          name: istiod-ca-cert",
    "        {{- end }}",
    "        - mountPath: /var/lib/istio/data",
    "          name: istio-data",
    "        # UDS channel between istioagent and gRPC client for XDS/SDS",
    "        - mountPath: /etc/istio/proxy",
    "          name: istio-xds",
    "        {{- if eq .Values.global.jwtPolicy \"third-party-jwt\" }}",
    "        - mountPath: /var/run/secrets/tokens",
    "          name: istio-token",
    "        {{- end }}",
    "        - name: istio-podinfo",
    "          mountPath: /etc/istio/pod",
    "        {{- if isset .ObjectMeta.Annotations `sidecar.istio.io/userVolumeMount` }}",
    "        {{ range $index, $value := fromJSON (index .ObjectMeta.Annotations `sidecar.istio.io/userVolumeMount`) }}",
    "        - name: \"{{  $index }}\"",
    "        {{ toYaml $value | indent 6 }}",
    "        {{ end }}",
    "        {{- end }}",
    "      volumes:",
    "      # UDS channel between istioagent and gRPC client for XDS/SDS",
    "      - emptyDir:",
    "          medium: Memory",
    "        name: istio-xds",
    "      - name: istio-data",
    "        emptyDir: {}",
    "      - name: istio-podinfo",
    "        downwardAPI:",
    "          items:",
    "            - path: \"labels\"",
    "              fieldRef:",
    "                fieldPath: metadata.labels",
    "            - path: \"annotations\"",
    "              fieldRef:",
    "                fieldPath: metadata.annotations",
    "    {{- if eq .Values.global.jwtPolicy \"third-party-jwt\" }}",
    "      - name: istio-token",
    "        projected:",
    "          sources:",
    "          - serviceAccountToken:",
    "              path: istio-token",
    "              expirationSeconds: 43200",
    "              audience: {{ .Values.global.sds.token.aud }}",
    "    {{- end }}",
    "      {{- if eq .Values.global.pilotCertProvider \"istiod\" }}",
    "      - name: istiod-ca-cert",
    "        configMap:",
    "          name: istio-ca-root-cert",
    "      {{- end }}",
    "      {{- if isset .ObjectMeta.Annotations `sidecar.istio.io/userVolume` }}",
    "      {{range $index, $value := fromJSON (index .ObjectMeta.Annotations `sidecar.istio.io/userVolume`) }}",
    "      - name: \"{{ $index }}\"",
    "      {{ toYaml $value | indent 4 }}",
    "      {{ end }}",
    "      {{ end }}"
  ]

  @insert_values [
    "{",
    "  \"global\": {",
    "    \"caAddress\": \"\",",
    "    \"caName\": \"\",",
    "    \"configCluster\": false,",
    "    \"defaultPodDisruptionBudget\": {",
    "      \"enabled\": true",
    "    },",
    "    \"defaultResources\": {",
    "      \"requests\": {",
    "        \"cpu\": \"10m\"",
    "      }",
    "    },",
    "    \"externalIstiod\": false,",
    "    \"hub\": \"docker.io/istio\",",
    "    \"imagePullPolicy\": \"\",",
    "    \"imagePullSecrets\": [],",
    "    \"istioNamespace\": \"battery-core\",",
    "    \"istiod\": {",
    "      \"enableAnalysis\": false",
    "    },",
    "    \"jwtPolicy\": \"third-party-jwt\",",
    "    \"logAsJson\": false,",
    "    \"logging\": {",
    "      \"level\": \"default:info\"",
    "    },",
    "    \"meshID\": \"\",",
    "    \"meshNetworks\": {},",
    "    \"mountMtlsCerts\": false,",
    "    \"multiCluster\": {",
    "      \"clusterName\": \"\",",
    "      \"enabled\": false",
    "    },",
    "    \"network\": \"\",",
    "    \"omitSidecarInjectorConfigMap\": false,",
    "    \"oneNamespace\": false,",
    "    \"operatorManageWebhooks\": false,",
    "    \"pilotCertProvider\": \"istiod\",",
    "    \"priorityClassName\": \"\",",
    "    \"proxy\": {",
    "      \"autoInject\": \"enabled\",",
    "      \"clusterDomain\": \"cluster.local\",",
    "      \"componentLogLevel\": \"misc:error\",",
    "      \"enableCoreDump\": false,",
    "      \"excludeIPRanges\": \"\",",
    "      \"excludeInboundPorts\": \"\",",
    "      \"excludeOutboundPorts\": \"\",",
    "      \"holdApplicationUntilProxyStarts\": false,",
    "      \"image\": \"proxyv2\",",
    "      \"includeIPRanges\": \"*\",",
    "      \"includeInboundPorts\": \"*\",",
    "      \"includeOutboundPorts\": \"\",",
    "      \"logLevel\": \"warning\",",
    "      \"privileged\": false,",
    "      \"readinessFailureThreshold\": 30,",
    "      \"readinessInitialDelaySeconds\": 1,",
    "      \"readinessPeriodSeconds\": 2,",
    "      \"resources\": {",
    "        \"limits\": {",
    "          \"cpu\": \"2000m\",",
    "          \"memory\": \"1024Mi\"",
    "        },",
    "        \"requests\": {",
    "          \"cpu\": \"100m\",",
    "          \"memory\": \"128Mi\"",
    "        }",
    "      },",
    "      \"statusPort\": 15020,",
    "      \"tracer\": \"zipkin\"",
    "    },",
    "    \"proxy_init\": {",
    "      \"image\": \"proxyv2\",",
    "      \"resources\": {",
    "        \"limits\": {",
    "          \"cpu\": \"2000m\",",
    "          \"memory\": \"1024Mi\"",
    "        },",
    "        \"requests\": {",
    "          \"cpu\": \"10m\",",
    "          \"memory\": \"10Mi\"",
    "        }",
    "      }",
    "    },",
    "    \"remotePilotAddress\": \"\",",
    "    \"sds\": {",
    "      \"token\": {",
    "        \"aud\": \"istio-ca\"",
    "      }",
    "    },",
    "    \"sts\": {",
    "      \"servicePort\": 0",
    "    },",
    "    \"tag\": \"1.13.2\",",
    "    \"tracer\": {",
    "      \"datadog\": {",
    "        \"address\": \"$(HOST_IP):8126\"",
    "      },",
    "      \"lightstep\": {",
    "        \"accessToken\": \"\",",
    "        \"address\": \"\"",
    "      },",
    "      \"stackdriver\": {",
    "        \"debug\": false,",
    "        \"maxNumberOfAnnotations\": 200,",
    "        \"maxNumberOfAttributes\": 200,",
    "        \"maxNumberOfMessageEvents\": 200",
    "      },",
    "      \"zipkin\": {",
    "        \"address\": \"\"",
    "      }",
    "    },",
    "    \"useMCP\": false",
    "  },",
    "  \"revision\": \"\",",
    "  \"sidecarInjectorWebhook\": {",
    "    \"alwaysInjectSelector\": [],",
    "    \"defaultTemplates\": [],",
    "    \"enableNamespacesByDefault\": false,",
    "    \"injectedAnnotations\": {},",
    "    \"neverInjectSelector\": [],",
    "    \"objectSelector\": {",
    "      \"autoInject\": true,",
    "      \"enabled\": true",
    "    },",
    "    \"rewriteAppHTTPProbe\": true,",
    "    \"templates\": {}",
    "  }",
    "}"
  ]

  def pod_disruption_budget(config) do
    namespace = NetworkSettings.namespace(config)

    spec = %{
      "minAvailable" => 1,
      "selector" => %{
        "matchLabels" => %{
          "battery/app" => "istiod",
          "battery/managed" => "true",
          "istio" => "pilot"
        }
      }
    }

    B.build_resource(:pod_disruption_budget)
    |> B.name("istiod")
    |> B.namespace(namespace)
    |> B.app_labels(@istiod_app)
    |> B.label("istio", "pilot")
    |> B.label("operator.istio.io/component", "Pilot")
    |> B.label("istio.io/rev", "default")
    |> B.spec(spec)
  end

  def config_map(config) do
    namespace = NetworkSettings.namespace(config)

    data = %{
      "mesh" => """
      defaultConfig:
        discoveryAddress: istiod.battery-core.svc:15012
        tracing:
          zipkin:
            address: zipkin.battery-core:9411
      enablePrometheusMerge: true
      rootNamespace: null
      trustDomain: cluster.local
      """,
      "meshNetworks" => "networks: {}"
    }

    B.build_resource(:config_map)
    |> B.namespace(namespace)
    |> B.name("istio")
    |> Map.put("data", data)
  end

  def config_map_1(config) do
    namespace = NetworkSettings.namespace(config)

    data = %{
      "config" => Enum.join(@insert_config, "\n"),
      "values" => Enum.join(@insert_values, "\n")
    }

    B.build_resource(:config_map)
    |> B.name("istio-sidecar-injector")
    |> B.namespace(namespace)
    |> B.app_labels(@istiod_app)
    |> B.label("istio.io/rev", "default")
    |> B.label("operator.istio.io/component", "Pilot")
    |> Map.put("data", data)
  end

  def service(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "v1",
      "kind" => "Service",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "istiod",
          "battery/managed" => "true",
          "istio" => "pilot",
          "istio.io/rev" => "default",
          "operator.istio.io/component" => "Pilot"
        },
        "name" => "istiod",
        "namespace" => namespace
      },
      "spec" => %{
        "ports" => [
          %{
            "name" => "grpc-xds",
            "port" => 15_010,
            "protocol" => "TCP"
          },
          %{
            "name" => "https-dns",
            "port" => 15_012,
            "protocol" => "TCP"
          },
          %{
            "name" => "https-webhook",
            "port" => 443,
            "protocol" => "TCP",
            "targetPort" => 15_017
          },
          %{
            "name" => "http-monitoring",
            "port" => 15_014,
            "protocol" => "TCP"
          }
        ],
        "selector" => %{
          "battery/app" => "istiod",
          "istio" => "pilot"
        }
      }
    }
  end

  def deployment(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "apps/v1",
      "kind" => "Deployment",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "istiod",
          "battery/managed" => "true",
          "istio" => "pilot",
          "istio.io/rev" => "default",
          "operator.istio.io/component" => "Pilot"
        },
        "name" => "istiod",
        "namespace" => namespace
      },
      "spec" => %{
        "selector" => %{
          "matchLabels" => %{
            "battery/managed" => "true",
            "istio" => "pilot"
          }
        },
        "strategy" => %{
          "rollingUpdate" => %{
            "maxSurge" => "100%",
            "maxUnavailable" => "25%"
          }
        },
        "template" => %{
          "metadata" => %{
            "annotations" => %{
              "prometheus.io/port" => "15014",
              "prometheus.io/scrape" => "true",
              "sidecar.istio.io/inject" => "false"
            },
            "labels" => %{
              "battery/app" => "istiod",
              "battery/managed" => "true",
              "istio" => "pilot",
              "istio.io/rev" => "default",
              "operator.istio.io/component" => "Pilot",
              "sidecar.istio.io/inject" => "false"
            }
          },
          "spec" => %{
            "containers" => [
              %{
                "args" => [
                  "discovery",
                  "--monitoringAddr=:15014",
                  "--log_output_level=default:info",
                  "--domain",
                  "cluster.local",
                  "--keepaliveMaxServerConnectionAge",
                  "30m"
                ],
                "env" => [
                  %{
                    "name" => "REVISION",
                    "value" => "default"
                  },
                  %{
                    "name" => "JWT_POLICY",
                    "value" => "third-party-jwt"
                  },
                  %{
                    "name" => "PILOT_CERT_PROVIDER",
                    "value" => "istiod"
                  },
                  %{
                    "name" => "POD_NAME",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "apiVersion" => "v1",
                        "fieldPath" => "metadata.name"
                      }
                    }
                  },
                  %{
                    "name" => "POD_NAMESPACE",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "apiVersion" => "v1",
                        "fieldPath" => "metadata.namespace"
                      }
                    }
                  },
                  %{
                    "name" => "SERVICE_ACCOUNT",
                    "valueFrom" => %{
                      "fieldRef" => %{
                        "apiVersion" => "v1",
                        "fieldPath" => "spec.serviceAccountName"
                      }
                    }
                  },
                  %{
                    "name" => "KUBECONFIG",
                    "value" => "/var/run/secrets/remote/config"
                  },
                  %{
                    "name" => "PILOT_TRACE_SAMPLING",
                    "value" => "1"
                  },
                  %{
                    "name" => "PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_OUTBOUND",
                    "value" => "true"
                  },
                  %{
                    "name" => "PILOT_ENABLE_PROTOCOL_SNIFFING_FOR_INBOUND",
                    "value" => "true"
                  },
                  %{
                    "name" => "ISTIOD_ADDR",
                    "value" => "istiod.battery-core.svc:15012"
                  },
                  %{
                    "name" => "PILOT_ENABLE_ANALYSIS",
                    "value" => "false"
                  },
                  %{
                    "name" => "CLUSTER_ID",
                    "value" => "Kubernetes"
                  }
                ],
                "image" => "docker.io/istio/pilot:1.13.2",
                "name" => "discovery",
                "ports" => [
                  %{
                    "containerPort" => 8080,
                    "protocol" => "TCP"
                  },
                  %{
                    "containerPort" => 15_010,
                    "protocol" => "TCP"
                  },
                  %{
                    "containerPort" => 15_017,
                    "protocol" => "TCP"
                  }
                ],
                "readinessProbe" => %{
                  "httpGet" => %{
                    "path" => "/ready",
                    "port" => 8080
                  },
                  "initialDelaySeconds" => 1,
                  "periodSeconds" => 3,
                  "timeoutSeconds" => 5
                },
                "resources" => %{
                  "requests" => %{
                    "cpu" => "500m",
                    "memory" => "2048Mi"
                  }
                },
                "securityContext" => %{
                  "allowPrivilegeEscalation" => false,
                  "capabilities" => %{
                    "drop" => [
                      "ALL"
                    ]
                  },
                  "readOnlyRootFilesystem" => true,
                  "runAsGroup" => 1337,
                  "runAsNonRoot" => true,
                  "runAsUser" => 1337
                },
                "volumeMounts" => [
                  %{
                    "mountPath" => "/var/run/secrets/tokens",
                    "name" => "istio-token",
                    "readOnly" => true
                  },
                  %{
                    "mountPath" => "/var/run/secrets/istio-dns",
                    "name" => "local-certs"
                  },
                  %{
                    "mountPath" => "/etc/cacerts",
                    "name" => "cacerts",
                    "readOnly" => true
                  },
                  %{
                    "mountPath" => "/var/run/secrets/remote",
                    "name" => "istio-kubeconfig",
                    "readOnly" => true
                  }
                ]
              }
            ],
            "securityContext" => %{
              "fsGroup" => 1337
            },
            "serviceAccountName" => "istiod",
            "volumes" => [
              %{
                "emptyDir" => %{
                  "medium" => "Memory"
                },
                "name" => "local-certs"
              },
              %{
                "name" => "istio-token",
                "projected" => %{
                  "sources" => [
                    %{
                      "serviceAccountToken" => %{
                        "audience" => "istio-ca",
                        "expirationSeconds" => 43_200,
                        "path" => "istio-token"
                      }
                    }
                  ]
                }
              },
              %{
                "name" => "cacerts",
                "secret" => %{
                  "optional" => true,
                  "secretName" => "cacerts"
                }
              },
              %{
                "name" => "istio-kubeconfig",
                "secret" => %{
                  "optional" => true,
                  "secretName" => "istio-kubeconfig"
                }
              }
            ]
          }
        }
      }
    }
  end

  def horizontal_pod_autoscaler(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "autoscaling/v2beta1",
      "kind" => "HorizontalPodAutoscaler",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "istiod",
          "battery/managed" => "true",
          "istio.io/rev" => "default",
          "operator.istio.io/component" => "Pilot"
        },
        "name" => "istiod",
        "namespace" => namespace
      },
      "spec" => %{
        "maxReplicas" => 5,
        "metrics" => [
          %{
            "resource" => %{
              "name" => "cpu",
              "targetAverageUtilization" => 80
            },
            "type" => "Resource"
          }
        ],
        "minReplicas" => 1,
        "scaleTargetRef" => %{
          "apiVersion" => "apps/v1",
          "kind" => "Deployment",
          "name" => "istiod"
        }
      }
    }
  end

  def envoy_filter(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "networking.istio.io/v1alpha3",
      "kind" => "EnvoyFilter",
      "metadata" => %{
        "labels" => %{
          "battery/managed" => "true",
          "istio.io/rev" => "default"
        },
        "name" => "stats-filter-1.11",
        "namespace" => namespace
      },
      "spec" => %{
        "configPatches" => [
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "SIDECAR_OUTBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.11.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "SIDECAR_INBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.11.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true,\n  \"metrics\": [\n    {\n      \"dimensions\": {\n        \"destination_cluster\": \"node.metadata['CLUSTER_ID']\",\n        \"source_cluster\": \"downstream_peer.cluster_id\"\n      }\n    }\n  ]\n}\n"
                      },
                      "root_id" => "stats_inbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_inbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "GATEWAY",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.11.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  end

  def envoy_filter_1(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "networking.istio.io/v1alpha3",
      "kind" => "EnvoyFilter",
      "metadata" => %{
        "labels" => %{
          "battery/managed" => "true",
          "istio.io/rev" => "default"
        },
        "name" => "tcp-stats-filter-1.11",
        "namespace" => namespace
      },
      "spec" => %{
        "configPatches" => [
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "SIDECAR_INBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.11.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"metrics\": [\n    {\n      \"dimensions\": {\n        \"destination_cluster\": \"node.metadata['CLUSTER_ID']\",\n        \"source_cluster\": \"downstream_peer.cluster_id\"\n      }\n    }\n  ]\n}\n"
                      },
                      "root_id" => "stats_inbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_inbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "SIDECAR_OUTBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.11.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "GATEWAY",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.11.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  end

  def envoy_filter_2(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "networking.istio.io/v1alpha3",
      "kind" => "EnvoyFilter",
      "metadata" => %{
        "labels" => %{
          "battery/managed" => "true",
          "istio.io/rev" => "default"
        },
        "name" => "stats-filter-1.12",
        "namespace" => namespace
      },
      "spec" => %{
        "configPatches" => [
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "SIDECAR_OUTBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.12.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "SIDECAR_INBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.12.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true,\n  \"metrics\": [\n    {\n      \"dimensions\": {\n        \"destination_cluster\": \"node.metadata['CLUSTER_ID']\",\n        \"source_cluster\": \"downstream_peer.cluster_id\"\n      }\n    }\n  ]\n}\n"
                      },
                      "root_id" => "stats_inbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_inbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "GATEWAY",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.12.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  end

  def envoy_filter_3(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "networking.istio.io/v1alpha3",
      "kind" => "EnvoyFilter",
      "metadata" => %{
        "labels" => %{
          "battery/managed" => "true",
          "istio.io/rev" => "default"
        },
        "name" => "tcp-stats-filter-1.12",
        "namespace" => namespace
      },
      "spec" => %{
        "configPatches" => [
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "SIDECAR_INBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.12.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"metrics\": [\n    {\n      \"dimensions\": {\n        \"destination_cluster\": \"node.metadata['CLUSTER_ID']\",\n        \"source_cluster\": \"downstream_peer.cluster_id\"\n      }\n    }\n  ]\n}\n"
                      },
                      "root_id" => "stats_inbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_inbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "SIDECAR_OUTBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.12.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "GATEWAY",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.12.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  end

  def envoy_filter_4(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "networking.istio.io/v1alpha3",
      "kind" => "EnvoyFilter",
      "metadata" => %{
        "labels" => %{
          "battery/managed" => "true",
          "istio.io/rev" => "default"
        },
        "name" => "stats-filter-1.13",
        "namespace" => namespace
      },
      "spec" => %{
        "configPatches" => [
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "SIDECAR_OUTBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.13.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "SIDECAR_INBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.13.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true,\n  \"metrics\": [\n    {\n      \"dimensions\": {\n        \"destination_cluster\": \"node.metadata['CLUSTER_ID']\",\n        \"source_cluster\": \"downstream_peer.cluster_id\"\n      }\n    }\n  ]\n}\n"
                      },
                      "root_id" => "stats_inbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_inbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "HTTP_FILTER",
            "match" => %{
              "context" => "GATEWAY",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.http_connection_manager",
                    "subFilter" => %{
                      "name" => "envoy.filters.http.router"
                    }
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.13.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" => "type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"disable_host_header_fallback\": true\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  end

  def envoy_filter_5(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "networking.istio.io/v1alpha3",
      "kind" => "EnvoyFilter",
      "metadata" => %{
        "labels" => %{
          "battery/managed" => "true",
          "istio.io/rev" => "default"
        },
        "name" => "tcp-stats-filter-1.13",
        "namespace" => namespace
      },
      "spec" => %{
        "configPatches" => [
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "SIDECAR_INBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.13.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" =>
                          "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\",\n  \"metrics\": [\n    {\n      \"dimensions\": {\n        \"destination_cluster\": \"node.metadata['CLUSTER_ID']\",\n        \"source_cluster\": \"downstream_peer.cluster_id\"\n      }\n    }\n  ]\n}\n"
                      },
                      "root_id" => "stats_inbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_inbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "SIDECAR_OUTBOUND",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.13.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          },
          %{
            "applyTo" => "NETWORK_FILTER",
            "match" => %{
              "context" => "GATEWAY",
              "listener" => %{
                "filterChain" => %{
                  "filter" => %{
                    "name" => "envoy.filters.network.tcp_proxy"
                  }
                }
              },
              "proxy" => %{
                "proxyVersion" => "^1\\.13.*"
              }
            },
            "patch" => %{
              "operation" => "INSERT_BEFORE",
              "value" => %{
                "name" => "istio.stats",
                "typed_config" => %{
                  "@type" => "type.googleapis.com/udpa.type.v1.TypedStruct",
                  "type_url" =>
                    "type.googleapis.com/envoy.extensions.filters.network.wasm.v3.Wasm",
                  "value" => %{
                    "config" => %{
                      "configuration" => %{
                        "@type" => "type.googleapis.com/google.protobuf.StringValue",
                        "value" => "{\n  \"debug\": \"false\",\n  \"stat_prefix\": \"istio\"\n}\n"
                      },
                      "root_id" => "stats_outbound",
                      "vm_config" => %{
                        "code" => %{
                          "local" => %{
                            "inline_string" => "envoy.wasm.stats"
                          }
                        },
                        "runtime" => "envoy.wasm.runtime.null",
                        "vm_id" => "tcp_stats_outbound"
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    }
  end

  def mutating_webhook_configuration(config) do
    namespace = NetworkSettings.namespace(config)

    %{
      "apiVersion" => "admissionregistration.k8s.io/v1",
      "kind" => "MutatingWebhookConfiguration",
      "metadata" => %{
        "labels" => %{
          "battery/app" => "sidecar-injector",
          "battery/managed" => "true",
          "istio.io/rev" => "default",
          "operator.istio.io/component" => "Pilot"
        },
        "name" => "istio-sidecar-injector-battery-core"
      },
      "webhooks" => [
        %{
          "admissionReviewVersions" => [
            "v1beta1",
            "v1"
          ],
          "clientConfig" => %{
            "caBundle" => "",
            "service" => %{
              "name" => "istiod",
              "namespace" => namespace,
              "path" => "/inject",
              "port" => 443
            }
          },
          "failurePolicy" => "Fail",
          "name" => "rev.namespace.sidecar-injector.istio.io",
          "namespaceSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "istio.io/rev",
                "operator" => "In",
                "values" => [
                  "default"
                ]
              },
              %{
                "key" => "istio-injection",
                "operator" => "DoesNotExist"
              }
            ]
          },
          "objectSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "sidecar.istio.io/inject",
                "operator" => "NotIn",
                "values" => [
                  "false"
                ]
              }
            ]
          },
          "rules" => [
            %{
              "apiGroups" => [
                ""
              ],
              "apiVersions" => [
                "v1"
              ],
              "operations" => [
                "CREATE"
              ],
              "resources" => [
                "pods"
              ]
            }
          ],
          "sideEffects" => "None"
        },
        %{
          "admissionReviewVersions" => [
            "v1beta1",
            "v1"
          ],
          "clientConfig" => %{
            "caBundle" => "",
            "service" => %{
              "name" => "istiod",
              "namespace" => namespace,
              "path" => "/inject",
              "port" => 443
            }
          },
          "failurePolicy" => "Fail",
          "name" => "rev.object.sidecar-injector.istio.io",
          "namespaceSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "istio.io/rev",
                "operator" => "DoesNotExist"
              },
              %{
                "key" => "istio-injection",
                "operator" => "DoesNotExist"
              }
            ]
          },
          "objectSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "sidecar.istio.io/inject",
                "operator" => "NotIn",
                "values" => [
                  "false"
                ]
              },
              %{
                "key" => "istio.io/rev",
                "operator" => "In",
                "values" => [
                  "default"
                ]
              }
            ]
          },
          "rules" => [
            %{
              "apiGroups" => [
                ""
              ],
              "apiVersions" => [
                "v1"
              ],
              "operations" => [
                "CREATE"
              ],
              "resources" => [
                "pods"
              ]
            }
          ],
          "sideEffects" => "None"
        },
        %{
          "admissionReviewVersions" => [
            "v1beta1",
            "v1"
          ],
          "clientConfig" => %{
            "caBundle" => "",
            "service" => %{
              "name" => "istiod",
              "namespace" => namespace,
              "path" => "/inject",
              "port" => 443
            }
          },
          "failurePolicy" => "Fail",
          "name" => "namespace.sidecar-injector.istio.io",
          "namespaceSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "istio-injection",
                "operator" => "In",
                "values" => [
                  "enabled"
                ]
              }
            ]
          },
          "objectSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "sidecar.istio.io/inject",
                "operator" => "NotIn",
                "values" => [
                  "false"
                ]
              }
            ]
          },
          "rules" => [
            %{
              "apiGroups" => [
                ""
              ],
              "apiVersions" => [
                "v1"
              ],
              "operations" => [
                "CREATE"
              ],
              "resources" => [
                "pods"
              ]
            }
          ],
          "sideEffects" => "None"
        },
        %{
          "admissionReviewVersions" => [
            "v1beta1",
            "v1"
          ],
          "clientConfig" => %{
            "caBundle" => "",
            "service" => %{
              "name" => "istiod",
              "namespace" => namespace,
              "path" => "/inject",
              "port" => 443
            }
          },
          "failurePolicy" => "Fail",
          "name" => "object.sidecar-injector.istio.io",
          "namespaceSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "istio-injection",
                "operator" => "DoesNotExist"
              },
              %{
                "key" => "istio.io/rev",
                "operator" => "DoesNotExist"
              }
            ]
          },
          "objectSelector" => %{
            "matchExpressions" => [
              %{
                "key" => "sidecar.istio.io/inject",
                "operator" => "In",
                "values" => [
                  "true"
                ]
              },
              %{
                "key" => "istio.io/rev",
                "operator" => "DoesNotExist"
              }
            ]
          },
          "rules" => [
            %{
              "apiGroups" => [
                ""
              ],
              "apiVersions" => [
                "v1"
              ],
              "operations" => [
                "CREATE"
              ],
              "resources" => [
                "pods"
              ]
            }
          ],
          "sideEffects" => "None"
        }
      ]
    }
  end

  def materialize(config) do
    %{
      "/pod_disruption_budget" => pod_disruption_budget(config),
      "/config_map" => config_map(config),
      "/config_map_1" => config_map_1(config),
      "/service" => service(config),
      "/deployment" => deployment(config),
      "/horizontal_pod_autoscaler" => horizontal_pod_autoscaler(config),
      "/envoy_filter" => envoy_filter(config),
      "/envoy_filter_1" => envoy_filter_1(config),
      "/envoy_filter_2" => envoy_filter_2(config),
      "/envoy_filter_3" => envoy_filter_3(config),
      "/envoy_filter_4" => envoy_filter_4(config),
      "/envoy_filter_5" => envoy_filter_5(config),
      "/mutating_webhook_configuration" => mutating_webhook_configuration(config)
    }
  end
end
