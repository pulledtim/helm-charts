{{/*
Get service port for api-gateway.
*/}}
{{- define "stellio.api_gateway.service.port" -}}
8080
{{- end -}}

{{/*
Get service port for kafka.
*/}}
{{- define "stellio.kafka.service.port" -}}
29092
{{- end -}}

{{/*
Get service port for postgres.
*/}}
{{- define "stellio.postgres.service.port" -}}
5432
{{- end -}}

{{/*
Get service port for search-service.
*/}}
{{- define "stellio.search.service.port" -}}
8083
{{- end -}}

{{/*
Get service port for subscription-service.
*/}}
{{- define "stellio.subscription.service.port" -}}
8084
{{- end -}}

{{/*
Generate stellio microservice deployment.

Params:
  - name - String. Name of deployment/microservice
  - deployment - Dict - Required. The deployment options:
    - image - Dict - Required. Image settings, see [ImageRoot](https://artifacthub.io/packages/helm/bitnami/common#imageroot) for the structure.
    - podAnnotations - Dict - Optional. The pod annotations.
    - podSecurityContext - Dict - Optional. The pod security context.
    - replicaCount - int - Optional.
    - postgresHost - String - Required. The postgres host.
    - postgresCredentialsSecret - String - Required. The postgres credentials secret.
    - resources - Dict - Optional. The container resources.
    - securityContext - Dict - Optional. The container security context.
    - service - Dict - Required. Service options.
    - enableCompression - bool - Optional. Enable compression.
  - global - Dict - Required. The global values.
    - usePostgresOperator - bool - Required. Whether to use the postgres operator.
  - context - Dict - Required. The context for the template evaluation.


*/}}
{{- define "stellio.deployment" -}}
{{- $mySvcPort := printf "stellio.%s.service.port" (.name | replace "-" "_" ) -}}
{{- $svcNameSearch := printf "%s-%s" (include "common.names.fullname" .context) "search" -}}
{{- $svcNameSubscription := printf "%s-%s" (include "common.names.fullname" .context) "subscription" -}}
{{- $svcNameKafka := printf "%s-%s" (include "common.names.fullname" .context) "kafka" -}}
{{- $svcKafkaPort := include "stellio.kafka.service.port" $ -}}
{{- $svcNamePsql := printf "%s-%s" (include "common.names.fullname" .context) "postgres" -}}
{{- $configNamePsql := printf "%s-%s" (include "common.names.fullname" .context) "postgres-config"  -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ printf "%s-%s" (include "common.names.fullname" .context) .name | quote }}
  namespace: {{ .context.Release.Namespace | quote }}
  labels: {{- include "common.labels.standard" .context | nindent 4 }}
    app.kubernetes.io/component: {{ .name }}
spec:
  replicas: {{ .deployment.replicaCount | default 1 }}
  selector:
    matchLabels: {{- include "common.labels.matchLabels" .context | nindent 6 }}
      app.kubernetes.io/component: {{ .name }}
  template:
    metadata:
      {{- with .deployment.podAnnotations | default dict }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels: {{- include "common.labels.matchLabels" .context | nindent 8 }}
        app.kubernetes.io/component: {{ .name }}
    spec:
      {{- include "common.images.renderPullSecrets" ( dict "images" (list .deployment.image) "context" .context) | indent 6 }}
      automountServiceAccountToken: false
      securityContext:
        {{- toYaml .deployment.podSecurityContext | default dict | nindent 8 }}
      containers:
        - name: {{ printf "%s-%s" .context.Chart.Name .name }}
          env:
            - name: APPLICATION_AUTHENTICATION_ENABLED
              value: "false"
            {{- if eq .name "api-gateway" }}
            - name: APPLICATION_SUBSCRIPTION_SERVICE_URL
              value: {{ $svcNameSubscription }}.{{ include "common.names.namespace" .context }}.svc.cluster.local
            - name: APPLICATION_SEARCH_SERVICE_URL
              value: {{ $svcNameSearch }}.{{ include "common.names.namespace" .context }}.svc.cluster.local
            - name: JAVA_OPTIONS
              value: -Dlogging.level.root=DEBUG -Dlogging.level.org.springframework=DEBUG
            - name: SERVER_COMPRESSION_ENABLED
              value: "{{ .deployment.enableCompression | default false }}"
            {{- else -}}
            {{- if eq .name "subscription" }}
            - name: APPLICATION_ENTITY_SERVICE-URL
              value: http://{{ $svcNameSearch }}.{{ include "common.names.namespace" .context }}.svc.cluster.local:{{ include "stellio.search.service.port" $  }}
            - name: APPLICATION_TENANTS_0_NAME
              value: default_dataspace
            - name: APPLICATION_TENANTS_0_ISSUER
              value: None
            - name: APPLICATION_TENANTS_0_DBSCHEMA
              value: default_dataspace
            {{- else -}}
            {{- if eq .name "search" }}
            - name: APPLICATION_TENANTS_0_NAME
              value: default_dataspace
            - name: APPLICATION_TENANTS_0_ISSUER
              value: None
            - name: APPLICATION_TENANTS_0_DBSCHEMA
              value: default_dataspace
            {{- end }}
            {{- end }}
            {{- if not .global.usePostgresOperator }}
            - name: SPRING_FLYWAY_URL
              value: jdbc:postgresql://{{ $svcNamePsql }}.{{ include "common.names.namespace" .context }}.svc.cluster.local/stellio_{{ .name }}
            - name: SPRING_PROFILES_ACTIVE
              value: docker
            - name: SPRING_R2DBC_URL
              value: r2dbc:pool:postgresql://{{ $svcNamePsql }}.{{ include "common.names.namespace" .context }}.svc.cluster.local/stellio_{{ .name }}
            - name: SPRING_R2DBC_USERNAME
              valueFrom:
                  secretKeyRef:
                    name: {{ $configNamePsql }}
                    key: username
            - name: SPRING_R2DBC_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ $configNamePsql }}
                  key: password
            {{- else -}}
            {{- if .global.usePostgresOperator }}
            - name: SPRING_FLYWAY_URL
              value: jdbc:postgresql://{{ .deployment.postgresHost }}/stellio_{{ .name }}
            - name: SPRING_PROFILES_ACTIVE
              value: docker  
            - name: SPRING_R2DBC_URL
              value: r2dbc:pool:postgresql://{{ .deployment.postgresHost }}/stellio_{{ .name }}
            - name: SPRING_R2DBC_USERNAME
              valueFrom:
                  secretKeyRef:
                    name: {{ .deployment.postgresCredentialsSecret }}
                    key: username
            - name: SPRING_R2DBC_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ .deployment.postgresCredentialsSecret }}
                  key: password
            {{- end }}
            {{- end }}
            - name: SPRING_CLOUD_STREAM_KAFKA_BINDER_BROKERS
              value: {{ $svcNameKafka }}.{{ include "common.names.namespace" .context }}.svc.cluster.local:{{ $svcKafkaPort }}
            - name: SPRING_KAFKA_BOOTSTRAP_SERVERS
              value: {{ $svcNameKafka }}.{{ include "common.names.namespace" .context }}.svc.cluster.local:{{ $svcKafkaPort }}
            {{- end }}
          {{- if eq .name "api-gateway" }}
          livenessProbe:
            httpGet:
              path: /ngsi-ld/v1/subscriptions?limit=1
              port: 8080
              scheme: HTTP
              httpHeaders:
              - name: NGSILD-Tenant
                value: default_dataspace
            timeoutSeconds: 2
            periodSeconds: 30
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /ngsi-ld/v1/types
              port: 8080
              scheme: HTTP
              httpHeaders:
              - name: NGSILD-Tenant
                value: default_dataspace
            timeoutSeconds: 2
            periodSeconds: 30
            successThreshold: 1
            failureThreshold: 3
          {{- end }}
          securityContext:
            {{- toYaml .deployment.securityContext | default dict | nindent 12 }}
          image: {{ include "common.images.image" (dict "imageRoot" .deployment.image "global" .context.Values.global ) }}
          imagePullPolicy: {{ .deployment.image.pullPolicy }}
          ports:
            - name: http
              containerPort: {{ include $mySvcPort .context }}
              protocol: TCP
          resources:
            {{- toYaml .deployment.resources | default dict | nindent 12 }}
{{- end }}

