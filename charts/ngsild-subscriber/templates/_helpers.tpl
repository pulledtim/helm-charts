{{/*
Expand the name of the chart.
*/}}
{{- define "ngsild-subscriber.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ngsild-subscriber.fullname" -}}
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
{{- define "ngsild-subscriber.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ngsild-subscriber.labels" -}}
helm.sh/chart: {{ include "ngsild-subscriber.chart" . }}
{{ include "ngsild-subscriber.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ngsild-subscriber.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ngsild-subscriber.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ngsild-subscriber.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ngsild-subscriber.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Pod annotations
*/}}
{{- define "ngsild-subscriber.podAnnotations" -}}
checksum/configMappings: {{ include (print $.Template.BasePath "/configmap-mappings.yaml") . | sha256sum }}
checksum/configResponses: {{ include (print $.Template.BasePath "/configmap-responses.yaml") . | sha256sum }}
{{- if .Values.podAnnotations }}
{{ .Values.podAnnotations }}
{{- end }}
{{- end }}

