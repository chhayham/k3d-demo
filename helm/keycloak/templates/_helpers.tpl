{{/*
Expand the name of the chart.
*/}}
{{- define "keycloak.name" -}}
{{- default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as the full name.
With the default release name `keycloak` this renders exactly `keycloak`,
matching the quickstarts reference.
*/}}
{{- define "keycloak.fullname" -}}
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
Headless Service name used as the StatefulSet serviceName for JGroups
discovery. Renders `keycloak-discovery` with the default release name.
*/}}
{{- define "keycloak.discoveryServiceName" -}}
{{- printf "%s-discovery" (include "keycloak.fullname" .) }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "keycloak.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
The quickstarts reference uses the minimal `app` label, so we mirror that
to keep the rendered output faithful.
*/}}
{{- define "keycloak.labels" -}}
app: keycloak
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "keycloak.selectorLabels" -}}
app: keycloak
{{- end }}

{{/*
Postgres labels (quickstarts reference: `app: postgres`).
*/}}
{{- define "keycloak.postgresLabels" -}}
app: postgres
{{- end }}

{{- define "keycloak.postgresSelectorLabels" -}}
app: postgres
{{- end }}
