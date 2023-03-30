{{/*
Return the Notifier RabbitMQ secret name
*/}}
{{- define "osie.notifier.rabbitmq.secretName" -}}
{{- if .Values.notifier.rabbitmq.auth.existingSecret -}}
    {{- printf "%s" .Values.notifier.rabbitmq.auth.existingSecret -}}
{{- else -}}
    {{- printf "%s-rabbitmq" (include "common.names.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the Notifier RabbitMQ secret key
*/}}
{{- define "osie.notifier.rabbitmq.secretKey" -}}
{{- if .Values.notifier.rabbitmq.auth.existingSecret -}}
    {{- if .Values.notifier.rabbitmq.auth.existingSecretPasswordKey }}
        {{- printf "%s" .Values.notifier.rabbitmq.auth.existingSecretPasswordKey -}}
    {{- else }}
        {{- "rabbitmq-password" }}
    {{- end }}

{{- else -}}
{{- "rabbitmq-password" }}
{{- end -}}
{{- end -}}

