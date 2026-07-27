{{- define "matrix-appservice-irc.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "matrix-appservice-irc.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "matrix-appservice-irc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "matrix-appservice-irc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "matrix-appservice-irc.name" . }}
{{- end -}}

{{- define "matrix-appservice-irc.componentSelectorLabels" -}}
{{ include "matrix-appservice-irc.selectorLabels" .context }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "matrix-appservice-irc.labels" -}}
helm.sh/chart: {{ include "matrix-appservice-irc.chart" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "matrix-appservice-irc.selectorLabels" . }}
{{- end -}}

{{- define "matrix-appservice-irc.componentLabels" -}}
{{ include "matrix-appservice-irc.labels" .context }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "matrix-appservice-irc.image" -}}
{{- if .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- else -}}
{{- .Values.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.poolImage" -}}
{{- if .Values.pool.image.tag -}}
{{- printf "%s:%s" .Values.pool.image.repository .Values.pool.image.tag -}}
{{- else -}}
{{- .Values.pool.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.postgresImage" -}}
{{- if .Values.postgres.image.tag -}}
{{- printf "%s:%s" .Values.postgres.image.repository .Values.postgres.image.tag -}}
{{- else -}}
{{- .Values.postgres.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.redisImage" -}}
{{- if .Values.redis.image.tag -}}
{{- printf "%s:%s" .Values.redis.image.repository .Values.redis.image.tag -}}
{{- else -}}
{{- .Values.redis.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.waitForRedisImage" -}}
{{- if .Values.waitForRedis.image.tag -}}
{{- printf "%s:%s" .Values.waitForRedis.image.repository .Values.waitForRedis.image.tag -}}
{{- else -}}
{{- .Values.waitForRedis.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.configMapName" -}}
{{- printf "%s-config" (include "matrix-appservice-irc.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationConfigMapName" -}}
{{- if .Values.registration.synapseConfigMapName -}}
{{- .Values.registration.synapseConfigMapName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-registration" (include "matrix-appservice-irc.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.ingressName" -}}
{{- if .Values.ingress.name -}}
{{- .Values.ingress.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-media-proxy" (include "matrix-appservice-irc.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.postgresFullname" -}}
{{- printf "%s-postgres" (include "matrix-appservice-irc.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "matrix-appservice-irc.redisFullname" -}}
{{- printf "%s-redis" (include "matrix-appservice-irc.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "matrix-appservice-irc.mediaProxyPublicUrl" -}}
{{- if .Values.mediaProxy.publicUrl -}}
{{- .Values.mediaProxy.publicUrl -}}
{{- else -}}
{{- printf "https://%s" (required "values.host is required (example: irc-media.example.com)" .Values.host) -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.mediaProxySigningKeySecretName" -}}
{{- if .Values.mediaProxy.existingSecret -}}
{{- .Values.mediaProxy.existingSecret -}}
{{- else if .Values.mediaProxy.managedSecret.name -}}
{{- .Values.mediaProxy.managedSecret.name -}}
{{- else -}}
{{- printf "%s-media-proxy-signing-key" (include "matrix-appservice-irc.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.ensureMediaProxySigningKey" -}}
{{- if not (hasKey .Values.mediaProxy "_computedSigningKey") -}}
{{- $useExistingSecret := ne (.Values.mediaProxy.existingSecret | default "") "" -}}
{{- $managedSecretEnabled := and (not $useExistingSecret) .Values.mediaProxy.managedSecret.enabled -}}
{{- $secretName := include "matrix-appservice-irc.mediaProxySigningKeySecretName" . -}}
{{- $secretKey := .Values.mediaProxy.signingKeySecretKey -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- $signingKey := .Values.mediaProxy.signingKey | default "" -}}
{{- if and (eq $signingKey "") $existing (hasKey $existing.data $secretKey) -}}
{{- $signingKey = (index $existing.data $secretKey | b64dec) -}}
{{- end -}}
{{- if eq $signingKey "" -}}
{{- if and .Values.mediaProxy.autoGenerate $managedSecretEnabled -}}
{{- $signingKey = (dict "kty" "oct" "alg" "HS512" "k" (randAlphaNum 64) "key_ops" (list "sign" "verify")) | toJson -}}
{{- else -}}
{{- fail (printf "mediaProxy.signingKey is required when missing from secret %q key %q (set mediaProxy.signingKey, set mediaProxy.existingSecret to a populated Secret, or enable mediaProxy.autoGenerate with mediaProxy.managedSecret.enabled=true)" $secretName $secretKey) -}}
{{- end -}}
{{- end -}}
{{- $_ := set .Values.mediaProxy "_computedSigningKey" $signingKey -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.mediaProxySigningKey" -}}
{{- include "matrix-appservice-irc.ensureMediaProxySigningKey" . -}}
{{- index .Values.mediaProxy "_computedSigningKey" -}}
{{- end -}}

{{- define "matrix-appservice-irc.homeserverDomain" -}}
{{- required "values.homeserver.domain is required (example: matrix.example.com)" .Values.homeserver.domain -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationServiceUrl" -}}
{{- if .Values.registration.serviceUrl -}}
{{- .Values.registration.serviceUrl -}}
{{- else -}}
{{- printf "http://%s.%s.svc.cluster.local:%v" (include "matrix-appservice-irc.fullname" .) .Release.Namespace .Values.service.appservicePort -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationUserRegex" -}}
{{- printf "@irc_.*:%s" (include "matrix-appservice-irc.homeserverDomain" .) -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationAliasRegex" -}}
{{- printf "#irc_.*:%s" (include "matrix-appservice-irc.homeserverDomain" .) -}}
{{- end -}}

{{- define "matrix-appservice-irc.databaseConnectionString" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $host := (get $postgres "host") | default "" -}}
{{- $port := (get $postgres "port") | default 5432 -}}
{{- if and (eq $host "") .Values.postgres.enabled -}}
{{- $host = include "matrix-appservice-irc.postgresFullname" . -}}
{{- $port = .Values.postgres.service.port -}}
{{- end -}}
{{- if eq $host "" -}}
{{- fail "values.database.postgres.host is required when postgres.enabled=false" -}}
{{- end -}}
{{- $database := include "matrix-appservice-irc.databasePostgresDatabase" . -}}
{{- $user := include "matrix-appservice-irc.databasePostgresUser" . -}}
{{- $password := include "matrix-appservice-irc.databasePostgresPassword" . -}}
{{- $sslMode := (get $postgres "sslMode") | default "" -}}
{{- $connectionString := printf "postgres://%s:%s@%s:%v/%s" ($user | urlquery) ($password | urlquery) $host $port ($database | urlquery) -}}
{{- if ne $sslMode "" -}}
{{- printf "%s?sslmode=%s" $connectionString ($sslMode | urlquery) -}}
{{- else -}}
{{- $connectionString -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.databasePostgresDatabase" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $database := (get $postgres "database") | default "" -}}
{{- required "values.database.postgres.database is required" $database -}}
{{- end -}}

{{- define "matrix-appservice-irc.databasePostgresUser" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $user := (get $postgres "user") | default "" -}}
{{- required "values.database.postgres.user is required" $user -}}
{{- end -}}

{{- define "matrix-appservice-irc.databasePostgresManagedSecretKey" -}}
POSTGRES_PASSWORD
{{- end -}}

{{- define "matrix-appservice-irc.databasePostgresPasswordSecretName" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $passwordCfg := (get $postgres "password") | default dict -}}
{{- $existingSecretName := (get $passwordCfg "existingSecret") | default "" -}}
{{- if ne $existingSecretName "" -}}
{{- $existingSecretName -}}
{{- else -}}
{{- include "matrix-appservice-irc.postgresFullname" . -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.databasePostgresPasswordSecretKey" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $passwordCfg := (get $postgres "password") | default dict -}}
{{- $existingSecretName := (get $passwordCfg "existingSecret") | default "" -}}
{{- if ne $existingSecretName "" -}}
{{- (get $passwordCfg "existingSecretKey") | default "password" -}}
{{- else -}}
{{- include "matrix-appservice-irc.databasePostgresManagedSecretKey" . -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.ensureDatabasePostgresPassword" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- if not (hasKey $postgres "_computedPassword") -}}
{{- $password := "" -}}
{{- if .Values.postgres.enabled -}}
{{- $managedSecretName := include "matrix-appservice-irc.postgresFullname" . -}}
{{- $managedSecretKey := include "matrix-appservice-irc.databasePostgresManagedSecretKey" . -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $managedSecretName -}}
{{- if and $existing (hasKey $existing "data") (hasKey $existing.data $managedSecretKey) -}}
{{- $password = (index $existing.data $managedSecretKey | b64dec) -}}
{{- else -}}
{{- $password = (randAlphaNum 64 | sha256sum) -}}
{{- end -}}
{{- end -}}
{{- if eq $password "" -}}
{{- fail "values.database.postgres.password.value or values.database.postgres.password.existingSecret is required when postgres.enabled=false" -}}
{{- end -}}
{{- $_ := set $postgres "_computedPassword" $password -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.databasePostgresPassword" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $passwordCfg := (get $postgres "password") | default dict -}}
{{- $password := (get $passwordCfg "value") | default "" -}}
{{- $existingSecretName := (get $passwordCfg "existingSecret") | default "" -}}
{{- $existingSecretKey := (get $passwordCfg "existingSecretKey") | default "password" -}}
{{- if and (ne $password "") (ne $existingSecretName "") -}}
{{- fail "values.database.postgres.password.value and values.database.postgres.password.existingSecret are mutually exclusive" -}}
{{- end -}}
{{- if ne $password "" -}}
{{- $password -}}
{{- else if ne $existingSecretName "" -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $existingSecretName -}}
{{- if and $existing (hasKey $existing "data") (hasKey $existing.data $existingSecretKey) -}}
{{- index $existing.data $existingSecretKey | b64dec -}}
{{- else -}}
{{- fail (printf "values.database.postgres.password.existingSecret %q must contain key %q in namespace %q" $existingSecretName $existingSecretKey .Release.Namespace) -}}
{{- end -}}
{{- else -}}
{{- include "matrix-appservice-irc.ensureDatabasePostgresPassword" . -}}
{{- index .Values.database.postgres "_computedPassword" -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.databasePostgresPasswordChecksum" -}}
{{- include "matrix-appservice-irc.ensureDatabasePostgresPassword" . -}}
{{- $payload := dict
  "secretName" (include "matrix-appservice-irc.databasePostgresPasswordSecretName" .)
  "secretKey" (include "matrix-appservice-irc.databasePostgresPasswordSecretKey" .)
  "password" (include "matrix-appservice-irc.databasePostgresPassword" .)
-}}
{{- toYaml $payload | sha256sum -}}
{{- end -}}

{{- define "matrix-appservice-irc.redisUrl" -}}
{{- if .Values.redis.url -}}
{{- .Values.redis.url -}}
{{- else if .Values.redis.enabled -}}
{{- printf "redis://%s:%v/0" (include "matrix-appservice-irc.redisFullname" .) .Values.redis.service.port -}}
{{- else -}}
{{- required "values.redis.url is required when redis.enabled=false" .Values.redis.url -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.waitForRedisHost" -}}
{{- include "matrix-appservice-irc.redisFullname" . -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationTokenSecretName" -}}
{{- if .Values.registration.existingSecret -}}
{{- .Values.registration.existingSecret -}}
{{- else if .Values.registration.managedSecret.name -}}
{{- .Values.registration.managedSecret.name -}}
{{- else -}}
{{- printf "%s-registration-tokens" (include "matrix-appservice-irc.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.ensureRegistrationTokens" -}}
{{- if not (hasKey .Values.registration "_computedTokens") -}}
{{- $useExistingSecret := ne (.Values.registration.existingSecret | default "") "" -}}
{{- $managedSecretEnabled := and (not $useExistingSecret) .Values.registration.managedSecret.enabled -}}
{{- $secretName := include "matrix-appservice-irc.registrationTokenSecretName" . -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- $asToken := .Values.registration.asToken | default "" -}}
{{- $hsToken := .Values.registration.hsToken | default "" -}}
{{- if and (eq $asToken "") $existing (hasKey $existing.data "asToken") -}}
{{- $asToken = (index $existing.data "asToken" | b64dec) -}}
{{- end -}}
{{- if and (eq $hsToken "") $existing (hasKey $existing.data "hsToken") -}}
{{- $hsToken = (index $existing.data "hsToken" | b64dec) -}}
{{- end -}}
{{- if eq $asToken "" -}}
{{- if and .Values.registration.autoGenerate $managedSecretEnabled -}}
{{- $asToken = (randAlphaNum 64 | sha256sum) -}}
{{- else -}}
{{- fail (printf "registration.asToken is required when missing from secret %q (set registration.asToken, set registration.existingSecret to a populated Secret, or enable registration.autoGenerate with registration.managedSecret.enabled=true)" $secretName) -}}
{{- end -}}
{{- end -}}
{{- if eq $hsToken "" -}}
{{- if and .Values.registration.autoGenerate $managedSecretEnabled -}}
{{- $hsToken = (randAlphaNum 64 | sha256sum) -}}
{{- else -}}
{{- fail (printf "registration.hsToken is required when missing from secret %q (set registration.hsToken, set registration.existingSecret to a populated Secret, or enable registration.autoGenerate with registration.managedSecret.enabled=true)" $secretName) -}}
{{- end -}}
{{- end -}}
{{- $_ := set .Values.registration "_computedTokens" (dict "asToken" $asToken "hsToken" $hsToken) -}}
{{- end -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationAsToken" -}}
{{- include "matrix-appservice-irc.ensureRegistrationTokens" . -}}
{{- index (index .Values.registration "_computedTokens") "asToken" -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationHsToken" -}}
{{- include "matrix-appservice-irc.ensureRegistrationTokens" . -}}
{{- index (index .Values.registration "_computedTokens") "hsToken" -}}
{{- end -}}

{{- define "matrix-appservice-irc.registrationConfig" -}}
id: {{ .Values.registration.id }}
url: {{ include "matrix-appservice-irc.registrationServiceUrl" . | quote }}
as_token: {{ include "matrix-appservice-irc.registrationAsToken" . | quote }}
hs_token: {{ include "matrix-appservice-irc.registrationHsToken" . | quote }}
sender_localpart: {{ .Values.registration.senderLocalpart | quote }}
rate_limited: {{ .Values.registration.rateLimited }}
namespaces:
  users:
    - exclusive: true
      regex: {{ include "matrix-appservice-irc.registrationUserRegex" . | squote }}
  aliases:
    - exclusive: true
      regex: {{ include "matrix-appservice-irc.registrationAliasRegex" . | squote }}
protocols:
{{- range .Values.registration.protocols }}
  - {{ . | quote }}
{{- end }}
{{- end -}}
