{{/*
Common labels
*/}}
{{- define "osie.labels" -}}
{{include "common.labels.standard" . }}
{{- if .component }}
app.kubernetes.io/component: {{ include "common.names.name" . }}-{{ .component }}
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "osie.selectorLabels" -}}
{{include "common.labels.matchLabels" . }}
app.kubernetes.io/component: {{ include "common.names.name" . }}-{{ .component }}
{{- end }}

{{/*
Return container image
*/}}
{{- define "osie.image" }}
{{- printf "%s:%s" .image.repository (.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
Return list of mongodb hosts
*/}}
{{- define "osie.mongodb.hosts" -}}
{{- print (join "," .Values.externalMongodb.hosts) -}}
{{- end -}}

{{/*
Return mongodb port
*/}}
{{- define "osie.mongodb.port" -}}
{{- print .Values.externalMongodb.port -}}
{{- end -}}

{{- define "osie.mongodb.tls" -}}
{{- if .Values.externalMongodb.tls.enabled -}}true{{- end -}}
{{- end -}}

{{- define "osie.mongodb.tlsCa" -}}
{{- if and (include "osie.mongodb.tls" .) (or .Values.externalMongodb.tls.caConfigMap .Values.externalMongodb.tls.caSecret) -}}true{{- end -}}
{{- end -}}

{{- define "osie.mongodb.caFile" -}}/opt/osie/tls/mongodb/ca.crt{{- end -}}

{{- define "osie.mongodb.queryParams" -}}
{{- $params := list -}}
{{- $extra := .Values.externalMongodb.extraQueryParams | default "" -}}
{{- $params = append $params $extra -}}
{{- if and (include "osie.mongodb.tls" .) (not (regexMatch "(^|&)(tls|ssl)=" $extra)) -}}
    {{- $params = append $params "tls=true" -}}
{{- end -}}
{{- join "&" (compact $params) -}}
{{- end -}}

{{/*
Return the MongoDB Secret Name
*/}}
{{- define "osie.mongodb.secretName" -}}
{{- if .Values.externalMongodb.existingSecret -}}
    {{- printf "%s" .Values.externalMongodb.existingSecret -}}
{{- else -}}
    {{- printf "%s-externalmongo" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Retrieve key of the MongoDB secret
*/}}
{{- define "osie.mongodb.secretKey" -}}
{{- if and .Values.externalMongodb.existingSecret .Values.externalMongodb.existingSecretPasswordKey -}}
    {{- printf "%s" .Values.externalMongodb.existingSecretPasswordKey -}}
{{- else -}}
    {{- print "mongodb-password" -}}
{{- end -}}
{{- end -}}


{{/**/}}
{{/*Retrieve key of the MongoDB secret*/}}
{{/**/}}
{{/*{{- define "osie.mongodb.secretKey" -}}*/}}
{{/*{{- if .Values.externalMongodb.existingSecret -}}*/}}
{{/*    {{- if .Values.externalMongodb.existingSecretUriKey -}}*/}}
{{/*        {{- printf "%s" .Values.externalMongodb.existingSecretUriKey -}}*/}}
{{/*    {{- else -}}*/}}
{{/*        {{- print "mongodb-uri" -}}*/}}
{{/*    {{- end -}}*/}}
{{/*{{- else -}}*/}}
{{/*    {{- print "mongodb-uri" -}}*/}}
{{/*{{- end -}}*/}}
{{/*{{- end -}}*/}}


{{/*
Return the MongoDB username: from existingSecret when existingSecretUsernameKey is set, otherwise from values
*/}}
{{- define "osie.mongodb.usernameEnv" -}}
{{- if .Values.externalMongodb.existingSecretUsernameKey -}}
valueFrom:
  secretKeyRef:
    name: {{ include "osie.mongodb.secretName" . }}
    key: {{ .Values.externalMongodb.existingSecretUsernameKey }}
{{- else -}}
value: {{ .Values.externalMongodb.username | quote }}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ username: from existingSecret when existingSecretUsernameKey is set, otherwise from values
*/}}
{{- define "osie.rabbitmq.usernameEnv" -}}
{{- if .Values.externalRabbitmq.existingSecretUsernameKey -}}
valueFrom:
  secretKeyRef:
    name: {{ include "osie.rabbitmq.secretName" . }}
    key: {{ .Values.externalRabbitmq.existingSecretUsernameKey }}
{{- else -}}
value: {{ include "osie.rabbitmq.user" . | quote }}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ host
*/}}
{{- define "osie.rabbitmq.host" -}}
{{- printf "%s" .Values.externalRabbitmq.host -}}
{{- end -}}

{{/*
Return the RabbitMQ Port
*/}}
{{- define "osie.rabbitmq.port" -}}
{{- printf "%d" (.Values.externalRabbitmq.port | int ) -}}
{{- end -}}

{{/*
Return the RabbitMQ username
*/}}
{{- define "osie.rabbitmq.user" -}}
{{- printf "%s" .Values.externalRabbitmq.username -}}
{{- end -}}

{{/*
Return the RabbitMQ secret name
*/}}
{{- define "osie.rabbitmq.secretName" -}}
{{- if .Values.externalRabbitmq.existingSecret -}}
    {{- printf "%s" .Values.externalRabbitmq.existingSecret -}}
{{- else -}}
    {{- printf "%s-%s" (include "common.names.fullname" .) "externalrabbitmq" -}}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ secret key
*/}}
{{- define "osie.rabbitmq.secretPasswordKey" -}}
{{- if .Values.externalRabbitmq.existingSecret -}}
    {{- if .Values.externalRabbitmq.existingSecretPasswordKey }}
        {{- printf "%s" .Values.externalRabbitmq.existingSecretPasswordKey -}}
    {{- else }}
        {{- "rabbitmq-password" }}
    {{- end }}
{{- else -}}
    {{- "rabbitmq-password" }}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ host
*/}}
{{- define "osie.rabbitmq.vhost" -}}
{{- printf "%s" (.Values.externalRabbitmq.vhost | default "/") -}}
{{- end -}}

{{- define "osie.rabbitmq.tls" -}}
{{- if .Values.externalRabbitmq.tls.enabled -}}true{{- end -}}
{{- end -}}

{{- define "osie.rabbitmq.tlsCa" -}}
{{- if and (include "osie.rabbitmq.tls" .) (or .Values.externalRabbitmq.tls.caConfigMap .Values.externalRabbitmq.tls.caSecret) -}}true{{- end -}}
{{- end -}}

{{- define "osie.rabbitmq.caFile" -}}/opt/osie/tls/rabbitmq/ca.crt{{- end -}}

{{- define "osie.externalTls.caSource" -}}
{{- $tls := .tls -}}
{{- if and $tls.caConfigMap $tls.caSecret -}}
    {{- fail (printf "%s.tls: set caConfigMap or caSecret, not both" .name) -}}
{{- end -}}
{{- if $tls.caSecret -}}
secret:
  secretName: {{ $tls.caSecret }}
  items:
    - key: {{ required (printf "%s.tls.caKey is required" .name) $tls.caKey }}
      path: ca.crt
{{- else -}}
configMap:
  name: {{ $tls.caConfigMap }}
  items:
    - key: {{ required (printf "%s.tls.caKey is required" .name) $tls.caKey }}
      path: ca.crt
{{- end -}}
{{- end -}}

{{- define "osie.externalTls.volumes" -}}
{{- if include "osie.mongodb.tlsCa" . }}
- name: mongodb-ca
  {{- include "osie.externalTls.caSource" (dict "name" "externalMongodb" "tls" .Values.externalMongodb.tls) | nindent 2 }}
{{- end }}
{{- if include "osie.rabbitmq.tlsCa" . }}
- name: rabbitmq-ca
  {{- include "osie.externalTls.caSource" (dict "name" "externalRabbitmq" "tls" .Values.externalRabbitmq.tls) | nindent 2 }}
{{- end }}
{{- end -}}

{{- define "osie.externalTls.volumeMounts" -}}
{{- if include "osie.mongodb.tlsCa" . }}
- name: mongodb-ca
  mountPath: {{ include "osie.mongodb.caFile" . | dir }}
  readOnly: true
{{- end }}
{{- if include "osie.rabbitmq.tlsCa" . }}
- name: rabbitmq-ca
  mountPath: {{ include "osie.rabbitmq.caFile" . | dir }}
  readOnly: true
{{- end }}
{{- end -}}

{{/*
Return the bcrypt password secret name
*/}}
{{- define "osie.bcrypt.secretName" -}}
{{- if .Values.encryption.bcrypt.existingPasswordSecret -}}
    {{- printf "%s" .Values.encryption.bcrypt.existingPasswordSecret -}}
{{- else -}}
    {{- printf "%s-bcrypt" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "osie.ui.oauth2IssuerUri" -}}
{{- if .Values.global.oauth2.issuerUri -}}
{{- .Values.global.oauth2.issuerUri -}}
{{- else if .Values.ui.oauth2.issuerUri -}}
{{- .Values.ui.oauth2.issuerUri -}}
{{- end -}}
{{- end -}}

{{- define "osie.admin.oauth2IssuerUri" -}}
{{- if .Values.global.oauth2.issuerUri -}}
{{- .Values.global.oauth2.issuerUri -}}
{{- else if .Values.admin.oauth2.issuerUri -}}
{{- .Values.admin.oauth2.issuerUri -}}
{{- end -}}
{{- end -}}

{{- define "osie.adminApi.oauth2IssuerUri" -}}
{{- if .Values.global.oauth2.issuerUri -}}
{{- .Values.global.oauth2.issuerUri -}}
{{- else if .Values.adminApi.oauth2.issuerUri -}}
{{- .Values.adminApi.oauth2.issuerUri -}}
{{- end -}}
{{- end -}}

{{- define "osie.oauth2ClientId" -}}
{{- if .Values.global.oauth2.clientId}}
{{ .Values.global.oauth2.clientId }}
{{- else }}
{{- required "oauth2 clientId is required" .oauth2.clientId }}
{{- end }}
{{- end -}}

{{- define "osie.oauth2Audience" -}}
{{- if .Values.global.oauth2.audience -}}
{{ .Values.global.oauth2.audience }}
{{- else -}}
{{- .oauth2.audience }}
{{- end }}
{{- end -}}

{{- define "osie.oauth2LogoutUrl" -}}
{{- if .Values.global.oauth2.logoutUrl -}}
{{ .Values.global.oauth2.logoutUrl }}
{{- else -}}
{{- .oauth2.logoutUrl }}
{{- end -}}
{{- end -}}

{{- define "osie.oauth2Scope" -}}
{{- if .Values.global.oauth2.scope -}}
{{ .Values.global.oauth2.scope }}
{{- else -}}
{{- .oauth2.scope }}
{{- end -}}
{{- end -}}

{{/*
Retrieve key of bcrypt secret key
*/}}
{{- define "osie.bcrypt.secretKey" -}}
{{- if .Values.encryption.bcrypt.existingPasswordSecret -}}
    {{- if .Values.encryption.bcrypt.existingPasswordSecretKey -}}
        {{- printf "%s" .Values.encryption.bcrypt.existingPasswordSecretKey -}}
    {{- else -}}
        {{- print "bcrypt-password" -}}
    {{- end -}}
{{- else -}}
    {{- print "bcrypt-password" -}}
{{- end -}}
{{- end -}}


{{/*
Expand the name of the chart.
*/}}
{{- define "osie.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{ include "common.tplvalues.render" }}
{{- define "osie.componentName" -}}
{{- printf "%s-%s" (include "common.names.fullname" .) .component | trunc 63 | trimSuffix "-"  }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "osie.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Bcrypt password
*/}}
{{- define "osie.bcryptPassword" }}

{{- end}}

{{- define "osie.waitForDBInitContainer" -}}
{{- $mongoParams := include "osie.mongodb.queryParams" . -}}
{{- if include "osie.mongodb.tlsCa" . -}}
{{- $mongoParams = join "&" (compact (list $mongoParams (printf "tlsCAFile=%s" (include "osie.mongodb.caFile" .)))) -}}
{{- end -}}
# We need to wait for the MongoDB database to be ready in order to start with Osie.
# As it is a ReplicaSet, we need that all nodes are configured in order to start with
# the application or race conditions can occur
- name: wait-for-db
  image: {{ include "osie.image" . | quote }}
  imagePullPolicy: {{ .image.pullPolicy }}
  securityContext:
    {{- toYaml .podSecurityContext | nindent 8 }}
  command:
    - bash
    - -ec
    - |
      #!/bin/bash

      set -o errexit
      set -o nounset
      set -o pipefail

      . /opt/osie/scripts/libosie.sh

      info "Waiting for MongoDB come up"
      for host in ${MONGODB_HOSTS//,/ }; do
            info "Waiting for host $host"
            osie_wait_for_mongodb_connection "mongodb://${MONGODB_USER}:${MONGODB_PASSWORD}@${host}:${MONGODB_PORT}/${MONGODB_DATABASE}{{ with $mongoParams }}?{{ . }}{{ end }}"
      done
      info "Database is ready"

      info "Waiting for RabbitMQ come up"
      if ! wait-for-port --host="${RABBITMQ_HOST}" --timeout=120 "${RABBITMQ_PORT}"; then
            error "Could not connect to ${RABBITMQ_HOST}:${RABBITMQ_PORT}"
            exit 1
      fi
      info "RabbitMQ is ready"

  {{- with (include "osie.externalTls.volumeMounts" . | trim) }}
  volumeMounts:
    {{- . | nindent 4 }}
  {{- end }}
  env:
    - name: MONGODB_HOSTS
      value: {{ include "osie.mongodb.hosts" . | quote }}
    - name: MONGODB_PORT
      value: {{ include "osie.mongodb.port" . | quote }}
    - name: MONGODB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: {{ include "osie.mongodb.secretName" . }}
          key: {{ include "osie.mongodb.secretKey" . }}
    - name: MONGODB_USER
      {{ include "osie.mongodb.usernameEnv" . | nindent 6 }}
    - name: MONGODB_DATABASE
      value: {{ .Values.externalMongodb.database | quote }}
    - name: RABBITMQ_HOST
      value: {{ include "osie.rabbitmq.host" . | quote }}
    - name: RABBITMQ_PORT
      value: {{ include "osie.rabbitmq.port" . | quote }}
{{- end -}}

{{- define "osie.ingressHostname" -}}
{{- tpl (.ingress.hostname | default .Values.global.ingress.hostname) . }}
{{- end -}}s

{{- define "osie.ingressRule" -}}
- host: {{ include "osie.ingressHostname" . | quote }}
  http:
    paths:
      - path: {{ tpl .ingress.path . }}
        pathType: {{ .ingress.pathType }}
        backend: {{- include "common.ingress.backend" (dict "serviceName" (include "osie.componentName" .) "servicePort" .ingress.servicePort "context" $)  | nindent 14 }}
{{- end -}}

{{/*
Public hostname of a component exposed through the Gateway API. Expects a component context.
*/}}
{{- define "osie.gatewayHostname" -}}
{{- tpl (.gateway.hostname | default .Values.global.gateway.hostname) . }}
{{- end -}}

{{/*
Gateways a component's HTTPRoute attaches to. Expects a component context.
*/}}
{{- define "osie.gatewayParentRefs" -}}
{{- $parentRefs := .gateway.parentRefs | default .Values.global.gateway.parentRefs -}}
{{- if not $parentRefs -}}
{{- fail "global.gateway.parentRefs must reference at least one Gateway when global.gateway.enabled is true" -}}
{{- end -}}
{{- include "common.tplvalues.render" (dict "value" $parentRefs "context" .) -}}
{{- end -}}

{{/*
HTTPRoute exposing a component through the Gateway API. Expects a component context.
*/}}
{{- define "osie.httpRoute" -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ include "osie.componentName" . }}
  namespace: {{ include "common.names.namespace" . | quote }}
  labels:
    {{- include "osie.labels" . | nindent 4 }}
    {{- with .Values.global.gateway.labels }}
    {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
    {{- end }}
  {{- with .Values.global.gateway.annotations }}
  annotations:
    {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- include "osie.gatewayParentRefs" . | nindent 4 }}
  {{- with (include "osie.gatewayHostname" .) }}
  hostnames:
    - {{ . | quote }}
  {{- end }}
  rules:
    - matches:
        {{- $context := . }}
        {{- range .gateway.paths }}
        - path:
            type: {{ $context.gateway.pathType }}
            value: {{ tpl . $context | quote }}
        {{- end }}
      {{- with .gateway.filters }}
      filters:
        {{- include "common.tplvalues.render" (dict "value" . "context" $) | nindent 8 }}
      {{- end }}
      {{- with .gateway.timeouts }}
      timeouts:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      backendRefs:
        - name: {{ include "osie.componentName" . }}
          port: {{ .service.port }}
{{- end -}}

{{- define "osie.httpScheme" -}}
{{- if or .Values.global.ingress.tls (and .Values.global.gateway.enabled .Values.global.gateway.tls) }}
    {{- "https" -}}
{{- else -}}
    {{- "http" -}}
{{- end -}}
{{- end -}}

{{- define "osie.uiServiceFQDN" -}}
{{- $uiContext := (merge dict . .Values.ui) -}}
{{- printf "%s.%s.svc.%s" (include "osie.componentName" $uiContext) (include "common.names.namespace" .) .Values.global.clusterDomain -}}
{{- end -}}

{{- define "osie.adminServiceFQDN" -}}
{{- $adminContext := (merge dict . .Values.admin) -}}
{{- printf "%s.%s.svc.%s" (include "osie.componentName" $adminContext) (include "common.names.namespace" .) .Values.global.clusterDomain -}}
{{- end -}}

{{- define "osie.uiUrl" -}}
{{- if .Values.ui.baseUrl -}}
{{- .Values.ui.baseUrl -}}
{{- else if .Values.global.ingress.enabled -}}
{{- printf "%s://%s" (include "osie.httpScheme" .) (.Values.ui.ingress.hostname | default .Values.global.ingress.hostname) -}}
{{- else if .Values.global.gateway.enabled -}}
{{- printf "%s://%s" (include "osie.httpScheme" .) (include "osie.gatewayHostname" (merge dict . .Values.ui)) -}}
{{- else -}}
{{- printf "http://%s:%v" (include "osie.uiServiceFQDN" .) .Values.ui.service.port -}}
{{- end -}}
{{- end -}}

{{- define "osie.adminUrl" -}}
{{- if .Values.admin.baseUrl -}}
{{- .Values.admin.baseUrl -}}
{{- else if .Values.global.ingress.enabled -}}
{{- printf "%s://%s/osie_admin" (include "osie.httpScheme" .) (.Values.admin.ingress.hostname | default .Values.global.ingress.hostname) -}}
{{- else if .Values.global.gateway.enabled -}}
{{- printf "%s://%s/osie_admin" (include "osie.httpScheme" .) (include "osie.gatewayHostname" (merge dict . .Values.admin)) -}}
{{- else -}}
{{- printf "http://%s:%v/osie_admin" (include "osie.adminServiceFQDN" .) .Values.admin.service.port -}}
{{- end -}}
{{- end -}}

{{- define "osie.apiServiceFQDN" -}}
{{- $apiContext := (merge dict . .Values.api) -}}
{{- printf "%s.%s.svc.%s" (include "osie.componentName" $apiContext) (include "common.names.namespace" .) .Values.global.clusterDomain -}}
{{- end -}}

{{- define "osie.apiBaseUrl" -}}
{{- if .Values.api.baseUrl -}}
{{- .Values.api.baseUrl -}}
{{- else if .Values.global.ingress.enabled -}}
{{- printf "%s://%s" (include "osie.httpScheme" .) (.Values.api.ingress.hostname | default .Values.global.ingress.hostname) -}}
{{- else if .Values.global.gateway.enabled -}}
{{- printf "%s://%s" (include "osie.httpScheme" .) (include "osie.gatewayHostname" (merge dict . .Values.api)) -}}
{{- else -}}
{{- printf "http://%s:%v" (include "osie.apiServiceFQDN" .) .Values.api.service.port -}}
{{- end -}}
{{- end -}}

{{- define "osie.apiUrl" -}}
{{- printf "%s/api-v1" (include "osie.apiBaseUrl" .) -}}
{{- end -}}

{{- define "osie.ui.accountConsoleUrl" }}
{{- .Values.ui.oauth2.accountConsoleUrl }}
{{- end }}

{{- define "osie.admin.accountConsoleUrl" }}
{{- .Values.admin.oauth2.accountConsoleUrl}}
{{- end }}

{{/* Fails while the release still runs the MongoDB, RabbitMQ or Keycloak earlier chart versions bundled */}}
{{- define "osie.bundledServicesGuard" -}}
{{- $migrate := "https://github.com/osie/deployment/tree/main/kubernetes/migrate-bundled" -}}
{{- $found := list -}}
{{- range $kind := list "Deployment" "StatefulSet" -}}
{{- range $o := (lookup "apps/v1" $kind $.Release.Namespace "").items | default list -}}
{{- $labels := $o.metadata.labels | default dict -}}
{{- if and (eq (get $labels "app.kubernetes.io/instance") $.Release.Name) (regexMatch "^(mongodb|rabbitmq|keycloak|postgresql)-[0-9]" (get $labels "helm.sh/chart")) -}}
{{- $found = append $found (printf "%s/%s" (lower $kind) $o.metadata.name) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if $found -}}
{{- fail (printf "\n\nRelease %s still runs the bundled MongoDB, RabbitMQ or Keycloak (%s), which this chart version no longer includes. Upgrading would delete them and their data, so nothing was changed. Stay on chart 26.8, move them with %s, then upgrade." $.Release.Name (join ", " $found) $migrate) -}}
{{- end -}}
{{- if not .Values.externalMongodb.hosts -}}
{{- fail (printf "\n\nexternalMongodb.hosts is required: this chart version no longer bundles MongoDB. A release that still runs the bundled MongoDB has to be moved first: %s" $migrate) -}}
{{- end -}}
{{- if not .Values.externalRabbitmq.host -}}
{{- fail (printf "\n\nexternalRabbitmq.host is required: this chart version no longer bundles RabbitMQ. A release that still runs the bundled RabbitMQ has to be moved first: %s" $migrate) -}}
{{- end -}}
{{- end -}}