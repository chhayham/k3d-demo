{{/*
Expand the name of the chart.
*/}}
{{- define "dex.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dex.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dex.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "dex.labels" -}}
helm.sh/chart: {{ include "dex.chart" . }}
{{ include "dex.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "dex.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dex.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
The public issuer base URL, e.g. https://dex.localhost/dex
This is what browsers and external clients see.
*/}}
{{- define "dex.issuer" -}}
{{- .Values.issuer.url | trimSuffix "/" }}
{{- end }}

{{/*
The cluster-internal base URL, e.g. http://dex.dex.svc.cluster.local:5556/dex
This is what in-cluster clients (Argo CD, Headlamp, pods) use to reach Dex.
*/}}
{{- define "dex.internalIssuer" -}}
{{- .Values.internalUrl | trimSuffix "/" }}
{{- end }}

{{/*
GitHub OIDC redirect URI. Must be registered in the GitHub OAuth App settings.
Format: <issuer>/callback
*/}}
{{- define "dex.githubRedirectURI" -}}
{{ include "dex.issuer" . }}/callback
{{- end }}
