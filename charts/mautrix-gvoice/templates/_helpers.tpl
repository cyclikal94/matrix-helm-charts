{{- define "mautrix-gvoice.runtimeSecretKeys" -}}
asToken,hsToken
{{- end -}}

{{- define "mautrix-gvoice.bridgeCommand" -}}
- mautrix-gvoice
{{- end -}}

{{- define "mautrix-gvoice.bridgeArgs" -}}
- -c
- /data/config.yaml
- --no-update
{{- end -}}

{{- define "mautrix-gvoice.registrationFileKey" -}}
appservice-registration-gvoice.yaml
{{- end -}}

{{- define "mautrix-gvoice.defaultRegistrationUserRegex" -}}
{{- printf "@%s_.*:%s" .Values.appservice.id (include "mautrix-go-base.homeserverDomain" .) -}}
{{- end -}}

{{- define "mautrix-gvoice.registrationConfig" -}}
{{ include "mautrix-go-base.registrationConfig" . }}
{{- end -}}

{{- define "mautrix-gvoice.doublePuppetRegistrationFileKey" -}}
appservice-registration-doublepuppet.yaml
{{- end -}}

{{- define "mautrix-gvoice.doublePuppetUserRegex" -}}
{{- $domain := include "mautrix-go-base.homeserverDomain" . -}}
{{- printf "@.*:%s" (replace "." "\\." $domain) -}}
{{- end -}}

{{- define "mautrix-gvoice.reservedBasePaths" -}}
homeserver.address,homeserver.domain,appservice.address,appservice.hostname,appservice.port,appservice.id,appservice.bot.username,appservice.as_token,appservice.hs_token,database.type,database.uri
{{- end -}}

{{- define "mautrix-gvoice.reservedNetworkPaths" -}}
{{- end -}}

{{- define "mautrix-gvoice.managedConfig" -}}
{{- $bot := .Values.appservice.bot | default dict -}}
{{- $managed := dict
  "homeserver" (dict
    "address" .Values.homeserver.address
    "domain" (include "mautrix-go-base.homeserverDomain" .)
  )
  "appservice" (dict
    "address" (include "mautrix-go-base.appserviceAddress" .)
    "hostname" .Values.appservice.hostname
    "port" .Values.appservice.port
    "id" .Values.appservice.id
    "as_token" (include "mautrix-go-base.runtimeSecretValue" (dict "root" . "key" "asToken"))
    "hs_token" (include "mautrix-go-base.runtimeSecretValue" (dict "root" . "key" "hsToken"))
    "bot" (dict
      "username" ((get $bot "username") | default "")
    )
  )
  "database" (dict
    "type" "postgres"
    "uri" (include "mautrix-go-base.databaseConnectionString" .)
  )
-}}
{{ toYaml $managed }}
{{- end -}}

{{- define "mautrix-gvoice.mergedConfig" -}}
{{ include "mautrix-go-base.bridgev2MergedConfig" . }}
{{- end -}}
