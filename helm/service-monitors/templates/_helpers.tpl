{{/*
Common labels applied to every ServiceMonitor.
Merges the chart-provided global labels with any per-entry labels.
Usage: {{ include "service-monitors.labels" (dict "root" . "entry" $entry) }}
*/}}
{{- define "service-monitors.labels" -}}
{{- $root := .root -}}
{{- $entry := .entry -}}
{{- $labels := dict -}}
{{- with $root.Values.globalLabels -}}
{{- $labels = merge (deepCopy $labels) . -}}
{{- end }}
{{- $labels = merge $labels (dict
      "app.kubernetes.io/name" $root.Chart.Name
      "app.kubernetes.io/instance" $root.Release.Name
      "app.kubernetes.io/managed-by" $root.Release.Service
      "helm.sh/chart" (printf "%s-%s" $root.Chart.Name $root.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-")
    ) -}}
{{- with $entry.labels -}}
{{- $labels = merge $labels . -}}
{{- end }}
{{- range $key, $value := $labels }}{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end }}
