{{- define "mautrix-telegram.runtimeSecretKeys" -}}
asToken,hsToken
{{- end -}}

{{- define "mautrix-telegram.bridgeCommand" -}}
- mautrix-telegram
{{- end -}}

{{- define "mautrix-telegram.bridgeArgs" -}}
- -c
- /data/config.yaml
- --no-update
{{- end -}}

{{- define "mautrix-telegram.registrationFileKey" -}}
appservice-registration-telegram.yaml
{{- end -}}

{{- define "mautrix-telegram.defaultRegistrationUserRegex" -}}
{{- printf "@%s_.*:%s" .Values.appservice.id (include "mautrix-go-base.homeserverDomain" .) -}}
{{- end -}}

{{- define "mautrix-telegram.registrationConfig" -}}
{{ include "mautrix-go-base.registrationConfig" . }}
{{- end -}}

{{- define "mautrix-telegram.doublePuppetRegistrationFileKey" -}}
appservice-registration-doublepuppet.yaml
{{- end -}}

{{- define "mautrix-telegram.doublePuppetUserRegex" -}}
{{- $domain := include "mautrix-go-base.homeserverDomain" . -}}
{{- printf "@.*:%s" (replace "." "\\." $domain) -}}
{{- end -}}

{{- define "mautrix-telegram.reservedBasePaths" -}}
homeserver.address,homeserver.domain,appservice.address,appservice.hostname,appservice.port,appservice.id,appservice.bot.username,appservice.as_token,appservice.hs_token,database.type,database.uri
{{- end -}}

{{- define "mautrix-telegram.reservedNetworkPaths" -}}
{{- end -}}

{{- define "mautrix-telegram.managedConfig" -}}
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

{{- define "mautrix-telegram.mergedConfig" -}}
{{ include "mautrix-go-base.bridgev2MergedConfig" . }}
{{- end -}}
