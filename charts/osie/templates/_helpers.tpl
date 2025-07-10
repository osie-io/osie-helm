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
Return MongoDB fullname
*/}}
{{- define "osie.mongodb.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "mongodb" "chartValues" .Values.mongodb "context" $) -}}
{{- end -}}

{{/*
Return list of mongodb hosts
*/}}
{{- define "osie.mongodb.hosts" -}}
{{- if .Values.mongodb.enabled -}}
    {{- $mongodbfullname := include "osie.mongodb.fullname" . -}}

    {{- if (eq .Values.mongodb.architecture "replicaset") }}
        {{- $replicas := .Values.mongodb.replicaCount | int }}
        {{- $hosts := printf "%s-0.%s-headless" $mongodbfullname $mongodbfullname -}}
        {{- range $i, $_e := until (sub $replicas 1 | int) }}
            {{- $hosts = printf "%s,%s-%d.%s-headless" $hosts $mongodbfullname (add $i 1 | int) $mongodbfullname -}}
        {{- end }}
        {{- print $hosts }}
    {{- else }}
        {{- print $mongodbfullname }}
    {{- end }}
{{- else -}}
    {{- print (join "," .Values.externalMongodb.hosts)  -}}
{{- end -}}
{{- end -}}

{{/*
Return mongodb port
*/}}
{{- define "osie.mongodb.port" -}}
{{- if .Values.mongodb.enabled -}}
    {{/* We are using the headless service so we need to use the container port */}}
    {{- print .Values.mongodb.containerPorts.mongodb -}}
{{- else -}}
    {{- print .Values.externalMongodb.port  -}}
{{- end -}}
{{- end -}}

{{/*
Return the MongoDB Secret Name
*/}}
{{- define "osie.mongodb.secretName" -}}
{{- if .Values.mongodb.enabled }}
    {{- printf "%s" (include "osie.mongodb.fullname" .) -}}
{{- else if .Values.externalMongodb.existingSecret -}}
    {{- printf "%s" .Values.externalMongodb.existingSecret -}}
{{- else -}}
    {{- printf "%s-externalmongo" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Retrieve key of the MongoDB secret
*/}}
{{- define "osie.mongodb.secretKey" -}}
{{- if .Values.mongodb.enabled -}}
    {{- print "mongodb-passwords" -}}
{{- else -}}
    {{- if .Values.externalMongodb.existingSecret -}}
        {{- if .Values.externalMongodb.existingSecretPasswordKey -}}
            {{- printf "%s" .Values.externalMongodb.existingSecretPasswordKey -}}
        {{- else -}}
            {{- print "mongodb-password" -}}
        {{- end -}}
    {{- else -}}
        {{- print "mongodb-password" -}}
    {{- end -}}
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
Return Redis(TM) fullname
*/}}
{{- define "osie.redis.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "redis" "chartValues" .Values.redis "context" $) -}}
{{- end -}}

{{/*
Create a default fully qualified redis name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osie.redis.host" -}}
{{- if .Values.redis.enabled -}}
    {{- printf "%s-master" (include "osie.redis.fullname" .) -}}
{{- else -}}
    {{- required "If the redis dependency is disabled you need to add an external redis host" .Values.externalRedis.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis&reg; port
*/}}
{{- define "osie.redis.port" -}}
{{- if .Values.redis.enabled }}
    {{- .Values.redis.master.service.ports.redis -}}
{{- else -}}
    {{- .Values.externalRedis.port -}}
{{- end -}}
{{- end -}}

{{/*
Return whether Redis&reg; uses password authentication or not
*/}}
{{- define "osie.redis.auth.enabled" -}}
{{- if or (and .Values.redis.enabled .Values.redis.auth.enabled) (and (not .Values.redis.enabled) (or .Values.externalRedis.password .Values.externalRedis.existingSecret)) }}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis&reg; secret key
*/}}
{{- define "osie.redis.secretPasswordKey" -}}
{{- if and .Values.redis.enabled .Values.redis.auth.existingSecret }}
    {{- .Values.redis.auth.existingSecretPasswordKey | printf "%s" }}
{{- else if and (not .Values.redis.enabled) .Values.externalRedis.existingSecret }}
    {{- .Values.externalRedis.existingSecretPasswordKey | printf "%s" }}
{{- else -}}
    {{- printf "redis-password" -}}
{{- end -}}
{{- end -}}

{{/*
Return the Redis&reg; secret name
*/}}
{{- define "osie.redis.secretName" -}}
{{- if .Values.redis.enabled }}
    {{- if .Values.redis.auth.existingSecret }}
        {{- printf "%s" .Values.redis.auth.existingSecret -}}
    {{- else -}}
        {{- printf "%s" (include "osie.redis.fullname" .) }}
    {{- end -}}
{{- else if .Values.externalRedis.existingSecret }}
    {{- printf "%s" .Values.externalRedis.existingSecret -}}
{{- else -}}
    {{- printf "%s-redis" (include "osie.redis.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name for RabbitMQ subchart
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "osie.rabbitmq.fullname" -}}
{{- include "common.names.dependency.fullname" (dict "chartName" "rabbitmq" "chartValues" .Values.rabbitmq "context" $) -}}
{{- end -}}

{{/*
Return the RabbitMQ host
*/}}
{{- define "osie.rabbitmq.host" -}}
{{- if .Values.rabbitmq.enabled }}
    {{- printf "%s" (include "osie.rabbitmq.fullname" .) -}}
{{- else -}}
    {{- printf "%s" .Values.externalRabbitmq.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ Port
*/}}
{{- define "osie.rabbitmq.port" -}}
{{- if .Values.rabbitmq.enabled }}
    {{- printf "%d" (.Values.rabbitmq.service.ports.amqp | int ) -}}
{{- else -}}
    {{- printf "%d" (.Values.externalRabbitmq.port | int ) -}}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ username
*/}}
{{- define "osie.rabbitmq.user" -}}
{{- if .Values.rabbitmq.enabled }}
    {{- printf "%s" .Values.rabbitmq.auth.username -}}
{{- else -}}
    {{- printf "%s" .Values.externalRabbitmq.username -}}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ secret name
*/}}
{{- define "osie.rabbitmq.secretName" -}}
{{- if .Values.externalRabbitmq.existingSecret -}}
    {{- printf "%s" .Values.externalRabbitmq.existingSecret -}}
{{- else if .Values.rabbitmq.enabled }}
    {{- printf "%s" (include "osie.rabbitmq.fullname" .) -}}
{{- else -}}
    {{- printf "%s-%s" (include "common.names.fullname" .) "externalrabbitmq" -}}
{{- end -}}
{{- end -}}

{{/*
Return the RabbitMQ secret key
*/}}
{{- define "osie.rabbitmq.secretPasswordKey" -}}
{{- if .Values.externalRabbitmq.existingSecret -}}
    {{- if .Values.rabbitmq.existingSecretPasswordKey }}
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
{{- if .Values.rabbitmq.enabled }}
    {{- printf "/" -}}
{{- else -}}
    {{- printf "%s" .Values.externalRabbitmq.vhost -}}
{{- end -}}
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

{{- define "osie.keycloakConfig.secretName" -}}
{{- printf "%s-env-secret" (include "common.names.dependency.fullname" (dict "chartName" "keycloak" "chartValues" .Values.keycloak "context" $)) }}
{{- end -}}

{{- define "osie.ui.oauth2IssuerUri" -}}
{{- if (and .Values.keycloak.enabled) }}
{{- printf "%s/realms/%s" (include "osie.keycloakUrl" . ) .Values.ui.realm.name }}
{{- else }}
{{- if .Values.global.oauth2.issuerUri }}
{{- .Values.global.oauth2.issuerUri }}
{{- else }}
{{- required "ui.oauth2.issuerUri is required" .Values.ui.oauth2.issuerUri -}}
{{- end }}
{{- end }}
{{- end -}}

{{- define "osie.admin.oauth2IssuerUri" -}}
{{- if (and .Values.keycloak.enabled (not .Values.admin.oauth2.issuerUri)) }}
{{- printf "%s/realms/%s" (include "osie.keycloakUrl" . ) .Values.admin.realm.name }}
{{- else }}
{{- if .Values.global.oauth2.issuerUri -}}
{{- .Values.global.oauth2.issuerUri }}
{{- else -}}
{{- required "admin.oauth2.issuerUri is required" .Values.admin.oauth2.issuerUri -}}
{{- end }}
{{- end }}
{{- end -}}

{{- define "osie.adminApi.oauth2IssuerUri" -}}
{{- if (and .Values.keycloak.enabled (not .Values.adminApi.oauth2.issuerUri)) }}
{{- printf "%s/realms/%s" (include "osie.keycloakUrl" . ) .Values.admin.realm.name }}
{{- else }}
{{- if .Values.global.oauth2.issuerUri -}}
{{- .Values.global.oauth2.issuerUri }}
{{- else -}}
{{- required "adminApi.oauth2.issuerUri is required" .Values.adminApi.oauth2.issuerUri -}}
{{- end }}
{{- end }}
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
            osie_wait_for_mongodb_connection "mongodb://${MONGODB_USER}:${MONGODB_PASSWORD}@${host}:${MONGODB_PORT}/${MONGODB_DATABASE}"
      done
      info "Database is ready"

      info "Waiting for RabbitMQ come up"
      osie_wait_for_http_connection "${RABBITMQ_HOST}:15672" 10 3
      info "RabbitMQ is ready"

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
      value: {{ ternary (index .Values.mongodb.auth.usernames 0) .Values.externalMongodb.username .Values.mongodb.enabled | quote }}
    - name: MONGODB_DATABASE
      value: {{ ternary (index .Values.mongodb.auth.databases 0) .Values.externalMongodb.database .Values.mongodb.enabled | quote }}
    - name: RABBITMQ_HOST
      value: {{ include "osie.rabbitmq.host" . | quote }}
{{- end -}}

{{- define "osie.ingressHostname" -}}
{{- tpl (.ingress.hostname | default .Values.global.ingress.hostname) . }}
{{- end -}}s

{{- define "osie.ingressRule" -}}
- host: {{ include "osie.ingressHostname" . | quote }}
  http:
    paths:
      - path: {{ tpl .ingress.path . }}
        {{- if eq "true" (include "common.ingress.supportsPathType" .) }}
        pathType: {{ .ingress.pathType }}
        {{- end }}
        backend: {{- include "common.ingress.backend" (dict "serviceName" (include "osie.componentName" .) "servicePort" .ingress.servicePort "context" $)  | nindent 14 }}
{{- end -}}

{{- define "osie.keycloakRealmConfigMap" -}}
{{- printf "%s-realm" (include "common.names.fullname" .) }}
{{- end -}}

{{- define "osie.httpScheme" -}}
{{- if .Values.global.ingress.tls }}
    {{- "https" -}}
{{- else -}}
    {{- "http" -}}
{{- end -}}
{{- end -}}

{{- define "osie.uiUrl" -}}
{{- printf "%s://%s" (include "osie.httpScheme" .) (.Values.ui.ingress.hostname | default .Values.global.ingress.hostname) -}}
{{- end -}}

{{- define "osie.adminUrl" -}}
{{- printf "%s://%s/osie_admin" (include "osie.httpScheme" .) (.Values.admin.ingress.hostname | default .Values.global.ingress.hostname) -}}
{{- end -}}

{{- define "osie.apiUrl" -}}
{{- printf "%s://%s%s" (include "osie.httpScheme" .) (.Values.api.ingress.hostname | default .Values.global.ingress.hostname) "/api-v1" -}}
{{- end -}}

{{- define "osie.keycloakUrl" -}}
{{- printf "%s://%s" (include "osie.httpScheme" .) (tpl (.Values.keycloak.ingress.hostname | default .Values.global.ingress.hostname) .) -}}
{{- end -}}

{{- define "osie.keycloak.auth.secretName" -}}
{{- if .Values.keycloak.auth.existingSecret -}}
{{- .Values.keycloak.auth.existingSecret }}
{{- else -}}
{{- printf "%s-keycloak" (include "common.names.fullname" .) }}
{{- end -}}
{{- end -}}

{{- define "osie.keycloak.smtp" }}
{{- if .Values.smtp.enabled -}}
smtpServer:
{{- if .Values.smtp.auth }}
  password: {{ required ".Values.smtp.password is required" .Values.smtp.password }}
  user: {{ required ".Values.smtp.user is required" .Values.smtp.user}}
  auth: true
{{- end }}
  starttls: {{ .Values.smtp.starttls }}
  port: {{ required ".Values.smtp.port is required" .Values.smtp.port }}
  host: {{ required ".Values.smtp.host is required" .Values.smtp.host }}
  from: {{ required ".Values.smtp.from is required" .Values.smtp.from }}
  fromDisplayName: {{ required ".Values.smtp.fromDisplayName is required" .Values.smtp.fromDisplayName }}
{{- end -}}
{{- end}}

{{- define "osie.ui.accountConsoleUrl" }}
{{- if (and .Values.keycloak.enabled (not .Values.ui.oauth2.accountConsoleUrl)) }}
{{- printf "%s/account" (include "osie.ui.oauth2IssuerUri" .) }}
{{- else }}
{{- .Values.ui.oauth2.accountConsoleUrl }}
{{- end }}
{{- end }}

{{- define "osie.admin.accountConsoleUrl" }}
{{- if (and .Values.keycloak.enabled (not .Values.admin.oauth2.accountConsoleUrl))}}
{{- printf "%s/account" (include "osie.admin.oauth2IssuerUri" .)}}
{{- else }}
{{- .Values.admin.oauth2.accountConsoleUrl}}
{{- end }}
{{- end }}