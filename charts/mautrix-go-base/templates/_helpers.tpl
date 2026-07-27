{{- define "mautrix-go-base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mautrix-go-base.fullname" -}}
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

{{- define "mautrix-go-base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mautrix-go-base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mautrix-go-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "mautrix-go-base.name" . }}
{{- end -}}

{{- define "mautrix-go-base.componentSelectorLabels" -}}
{{ include "mautrix-go-base.selectorLabels" .context }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "mautrix-go-base.labels" -}}
helm.sh/chart: {{ include "mautrix-go-base.chart" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "mautrix-go-base.selectorLabels" . }}
{{- end -}}

{{- define "mautrix-go-base.componentLabels" -}}
{{ include "mautrix-go-base.labels" .context }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{- define "mautrix-go-base.image" -}}
{{- if .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- else -}}
{{- .Values.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.postgresImage" -}}
{{- if .Values.postgres.image.tag -}}
{{- printf "%s:%s" .Values.postgres.image.repository .Values.postgres.image.tag -}}
{{- else -}}
{{- .Values.postgres.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.configSecretName" -}}
{{- printf "%s-config" (include "mautrix-go-base.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mautrix-go-base.registrationConfigMapName" -}}
{{- if .Values.registration.synapseConfigMapName -}}
{{- .Values.registration.synapseConfigMapName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-registration" (include "mautrix-go-base.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.runtimeSecretName" -}}
{{- if .Values.registration.existingSecret -}}
{{- .Values.registration.existingSecret -}}
{{- else if .Values.registration.managedSecret.name -}}
{{- .Values.registration.managedSecret.name -}}
{{- else -}}
{{- printf "%s-runtime-secrets" (include "mautrix-go-base.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.postgresFullname" -}}
{{- printf "%s-postgres" (include "mautrix-go-base.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mautrix-go-base.homeserverDomain" -}}
{{- required "values.homeserver.domain is required (example: matrix.example.com)" .Values.homeserver.domain -}}
{{- end -}}

{{- define "mautrix-go-base.databasePostgresDatabase" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $database := (get $postgres "database") | default "" -}}
{{- required "values.database.postgres.database is required" $database -}}
{{- end -}}

{{- define "mautrix-go-base.databasePostgresUser" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $user := (get $postgres "user") | default "" -}}
{{- required "values.database.postgres.user is required" $user -}}
{{- end -}}

{{- define "mautrix-go-base.databasePostgresManagedSecretKey" -}}
password
{{- end -}}

{{- define "mautrix-go-base.databasePostgresPasswordSecretName" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $passwordCfg := (get $postgres "password") | default dict -}}
{{- $existingSecretName := (get $passwordCfg "existingSecret") | default "" -}}
{{- if ne $existingSecretName "" -}}
{{- $existingSecretName -}}
{{- else -}}
{{- include "mautrix-go-base.postgresFullname" . -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.databasePostgresPasswordSecretKey" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $passwordCfg := (get $postgres "password") | default dict -}}
{{- $existingSecretName := (get $passwordCfg "existingSecret") | default "" -}}
{{- if ne $existingSecretName "" -}}
{{- (get $passwordCfg "existingSecretKey") | default "password" -}}
{{- else -}}
{{- include "mautrix-go-base.databasePostgresManagedSecretKey" . -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.ensureDatabasePostgresPassword" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- if not (hasKey $postgres "_computedPassword") -}}
{{- $password := "" -}}
{{- if .Values.postgres.enabled -}}
{{- $managedSecretName := include "mautrix-go-base.postgresFullname" . -}}
{{- $managedSecretKey := include "mautrix-go-base.databasePostgresManagedSecretKey" . -}}
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

{{- define "mautrix-go-base.databasePostgresPassword" -}}
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
{{- include "mautrix-go-base.ensureDatabasePostgresPassword" . -}}
{{- index .Values.database.postgres "_computedPassword" -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.databasePostgresPasswordChecksum" -}}
{{- include "mautrix-go-base.ensureDatabasePostgresPassword" . -}}
{{- $payload := dict
  "secretName" (include "mautrix-go-base.databasePostgresPasswordSecretName" .)
  "secretKey" (include "mautrix-go-base.databasePostgresPasswordSecretKey" .)
  "password" (include "mautrix-go-base.databasePostgresPassword" .)
-}}
{{- toYaml $payload | sha256sum -}}
{{- end -}}

{{- define "mautrix-go-base.databaseConnectionString" -}}
{{- $postgres := .Values.database.postgres | default dict -}}
{{- $host := (get $postgres "host") | default "" -}}
{{- $port := (get $postgres "port") | default 5432 -}}
{{- if and (eq $host "") .Values.postgres.enabled -}}
{{- $host = include "mautrix-go-base.postgresFullname" . -}}
{{- $port = .Values.postgres.service.port -}}
{{- end -}}
{{- if eq $host "" -}}
{{- fail "values.database.postgres.host is required when postgres.enabled=false" -}}
{{- end -}}
{{- $database := include "mautrix-go-base.databasePostgresDatabase" . -}}
{{- $user := include "mautrix-go-base.databasePostgresUser" . -}}
{{- $password := include "mautrix-go-base.databasePostgresPassword" . -}}
{{- $sslMode := (get $postgres "sslMode") | default "" -}}
{{- $connectionString := printf "postgres://%s:%s@%s:%v/%s" ($user | urlquery) ($password | urlquery) $host $port ($database | urlquery) -}}
{{- if ne $sslMode "" -}}
{{- printf "%s?sslmode=%s" $connectionString ($sslMode | urlquery) -}}
{{- else -}}
{{- $connectionString -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.appserviceAddress" -}}
{{- if .Values.appservice.address -}}
{{- .Values.appservice.address -}}
{{- else -}}
{{- printf "http://%s.%s.svc.cluster.local:%v" (include "mautrix-go-base.fullname" .) .Release.Namespace .Values.service.port -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.registrationServiceUrl" -}}
{{- if .Values.registration.serviceUrl -}}
{{- .Values.registration.serviceUrl -}}
{{- else -}}
{{- include "mautrix-go-base.appserviceAddress" . -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.registrationSenderLocalpart" -}}
{{- if .Values.registration.senderLocalpart -}}
{{- .Values.registration.senderLocalpart -}}
{{- else -}}
{{- $bot := .Values.appservice.bot | default dict -}}
{{- $username := (get $bot "username") | default "" -}}
{{- required "values.registration.senderLocalpart or values.appservice.bot.username is required" $username -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.registrationUserRegex" -}}
{{- if .Values.registration.userRegex -}}
{{- .Values.registration.userRegex -}}
{{- else -}}
{{- include (printf "%s.defaultRegistrationUserRegex" .Chart.Name) . -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetEnabled" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- if hasKey $doublePuppet "enabled" -}}
{{- if (get $doublePuppet "enabled") -}}true{{- else -}}false{{- end -}}
{{- else -}}
true
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetBaseVersion" -}}
{{- $version := "" -}}
{{- range $dependency := .Chart.Dependencies -}}
{{- if eq $dependency.Name "mautrix-go-base" -}}
{{- $version = $dependency.Version -}}
{{- end -}}
{{- end -}}
{{- if eq $version "" -}}
{{- fail "unable to resolve mautrix-go-base dependency version from chart dependencies; set values.doublePuppet.registration.id explicitly" -}}
{{- end -}}
{{- $version | lower | replace "+" "-" -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRegistrationID" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $registration := (get $doublePuppet "registration") | default dict -}}
{{- $id := (get $registration "id") | default "" -}}
{{- if ne $id "" -}}
{{- $id -}}
{{- else -}}
{{- printf "doublepuppet-%s" (include "mautrix-go-base.doublePuppetBaseVersion" .) -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRegistrationFileKey" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $registration := (get $doublePuppet "registration") | default dict -}}
{{- $fileKey := (get $registration "fileKey") | default "" -}}
{{- if ne $fileKey "" -}}
{{- $fileKey -}}
{{- else -}}
{{- include (printf "%s.doublePuppetRegistrationFileKey" .Chart.Name) . -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRegistrationConfigMapName" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $registration := (get $doublePuppet "registration") | default dict -}}
{{- $name := (get $registration "configMapName") | default "" -}}
{{- if ne $name "" -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-registration" (include "mautrix-go-base.doublePuppetRegistrationID" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRuntimeSecretName" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $registration := (get $doublePuppet "registration") | default dict -}}
{{- $existingSecret := (get $registration "existingSecret") | default "" -}}
{{- $managedSecret := (get $registration "managedSecret") | default dict -}}
{{- $managedName := (get $managedSecret "name") | default "" -}}
{{- if ne $existingSecret "" -}}
{{- $existingSecret -}}
{{- else if ne $managedName "" -}}
{{- $managedName -}}
{{- else -}}
{{- printf "%s-doublepuppet-runtime-secrets" (include "mautrix-go-base.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetSynapseNamespace" -}}
{{- $synapseNamespace := .Values.registration.synapseNamespace | default "" | trim -}}
{{- if ne $synapseNamespace "" -}}
{{- $synapseNamespace -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetReuseEnabled" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $reuse := (get $doublePuppet "reuseExisting") | default dict -}}
{{- if hasKey $reuse "enabled" -}}
{{- if (get $reuse "enabled") -}}true{{- else -}}false{{- end -}}
{{- else -}}
true
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetReuseConfigMapName" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $reuse := (get $doublePuppet "reuseExisting") | default dict -}}
{{- $name := (get $reuse "configMapName") | default "" -}}
{{- if ne $name "" -}}
{{- $name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- include "mautrix-go-base.doublePuppetRegistrationConfigMapName" . -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetReuseFileKey" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $reuse := (get $doublePuppet "reuseExisting") | default dict -}}
{{- $fileKey := (get $reuse "fileKey") | default "" -}}
{{- if ne $fileKey "" -}}
{{- $fileKey -}}
{{- else -}}
{{- include "mautrix-go-base.doublePuppetRegistrationFileKey" . -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetUserRegex" -}}
{{ include (printf "%s.doublePuppetUserRegex" .Chart.Name) . }}
{{- end -}}

{{- define "mautrix-go-base.ensureDoublePuppetRegistrationData" -}}
{{- if eq (include "mautrix-go-base.doublePuppetEnabled" .) "true" -}}
{{- if not (hasKey .Values "doublePuppet") -}}
{{- $_ := set .Values "doublePuppet" (dict) -}}
{{- end -}}
{{- $doublePuppet := .Values.doublePuppet -}}
{{- if not (hasKey $doublePuppet "_computedRegistration") -}}
{{- $registration := (get $doublePuppet "registration") | default dict -}}
{{- $existingSecretName := (get $registration "existingSecret") | default "" -}}
{{- $managedSecret := (get $registration "managedSecret") | default dict -}}
{{- $managedSecretEnabled := false -}}
{{- if eq $existingSecretName "" -}}
{{- if hasKey $managedSecret "enabled" -}}
{{- $managedSecretEnabled = (get $managedSecret "enabled") -}}
{{- else -}}
{{- $managedSecretEnabled = true -}}
{{- end -}}
{{- end -}}
{{- $autoGenerate := true -}}
{{- if hasKey $registration "autoGenerate" -}}
{{- $autoGenerate = (get $registration "autoGenerate") -}}
{{- end -}}

{{- $computed := dict
  "reuseFound" false
  "reuseNamespace" (include "mautrix-go-base.doublePuppetSynapseNamespace" .)
  "reuseConfigMapName" (include "mautrix-go-base.doublePuppetReuseConfigMapName" .)
  "reuseFileKey" (include "mautrix-go-base.doublePuppetReuseFileKey" .)
-}}

{{- if eq (include "mautrix-go-base.doublePuppetReuseEnabled" .) "true" -}}
{{- $reuseNamespace := include "mautrix-go-base.doublePuppetSynapseNamespace" . -}}
{{- $reuseConfigMapName := include "mautrix-go-base.doublePuppetReuseConfigMapName" . -}}
{{- $reuseFileKey := include "mautrix-go-base.doublePuppetReuseFileKey" . -}}
{{- $reuseConfigMap := lookup "v1" "ConfigMap" $reuseNamespace $reuseConfigMapName -}}
{{- if $reuseConfigMap -}}
{{- if not (hasKey $reuseConfigMap.data $reuseFileKey) -}}
{{- fail (printf "doublePuppet reuse configmap %s/%s does not contain key %q" $reuseNamespace $reuseConfigMapName $reuseFileKey) -}}
{{- end -}}
{{- $reuseRegistrationRaw := index $reuseConfigMap.data $reuseFileKey -}}
{{- $reuseRegistration := fromYaml $reuseRegistrationRaw -}}
{{- if and (kindIs "map" $reuseRegistration) (hasKey $reuseRegistration "Error") -}}
{{- fail (printf "doublePuppet reuse configmap %s/%s key %q must be valid YAML mapping" $reuseNamespace $reuseConfigMapName $reuseFileKey) -}}
{{- end -}}
{{- if not (kindIs "map" $reuseRegistration) -}}
{{- fail (printf "doublePuppet reuse configmap %s/%s key %q must be a YAML mapping" $reuseNamespace $reuseConfigMapName $reuseFileKey) -}}
{{- end -}}
{{- $reuseAsToken := (get $reuseRegistration "as_token") | default "" -}}
{{- if eq $reuseAsToken "" -}}
{{- fail (printf "doublePuppet reuse configmap %s/%s key %q must contain as_token" $reuseNamespace $reuseConfigMapName $reuseFileKey) -}}
{{- end -}}
{{- $_ := set $computed "reuseFound" true -}}
{{- $_ := set $computed "asTokenFromReuse" $reuseAsToken -}}
{{- $_ := set $computed "hsTokenFromReuse" ((get $reuseRegistration "hs_token") | default "") -}}
{{- $_ := set $computed "senderLocalpartFromReuse" ((get $reuseRegistration "sender_localpart") | default "") -}}
{{- end -}}
{{- end -}}

{{- $existingSecret := dict -}}
{{- if ne $existingSecretName "" -}}
{{- $existingSecret = (lookup "v1" "Secret" .Release.Namespace $existingSecretName) | default dict -}}
{{- end -}}
{{- $managedSecretName := include "mautrix-go-base.doublePuppetRuntimeSecretName" . -}}
{{- $managedRuntimeSecret := dict -}}
{{- if and (eq $existingSecretName "") $managedSecretEnabled -}}
{{- $managedRuntimeSecret = (lookup "v1" "Secret" .Release.Namespace $managedSecretName) | default dict -}}
{{- end -}}

{{- $keys := list "asToken" "hsToken" "senderLocalpart" -}}
{{- range $idx, $key := $keys -}}
{{- $value := (get $registration $key) | default "" -}}
{{- if eq $value "generate" -}}
{{- fail (printf "values.doublePuppet.registration.%s must not be set to 'generate'; leave empty for auto-generation" $key) -}}
{{- end -}}
{{- if and (eq $value "") (ne $existingSecretName "") -}}
{{- if and $existingSecret (hasKey $existingSecret "data") (hasKey $existingSecret.data $key) -}}
{{- $value = (index $existingSecret.data $key | b64dec) -}}
{{- else -}}
{{- fail (printf "doublePuppet.registration.%s is required when missing from secret %q (set doublePuppet.registration.%s, populate doublePuppet.registration.existingSecret, or enable auto-generation with managed secret mode)" $key $existingSecretName $key) -}}
{{- end -}}
{{- end -}}
{{- if and (eq $value "") (eq $key "asToken") (get $computed "reuseFound") -}}
{{- $value = (get $computed "asTokenFromReuse") | default "" -}}
{{- end -}}
{{- if and (eq $value "") (eq $key "hsToken") (get $computed "reuseFound") -}}
{{- $value = (get $computed "hsTokenFromReuse") | default "" -}}
{{- end -}}
{{- if and (eq $value "") (eq $key "senderLocalpart") (get $computed "reuseFound") -}}
{{- $value = (get $computed "senderLocalpartFromReuse") | default "" -}}
{{- end -}}
{{- if and (eq $value "") $managedRuntimeSecret (hasKey $managedRuntimeSecret "data") (hasKey $managedRuntimeSecret.data $key) -}}
{{- $value = (index $managedRuntimeSecret.data $key | b64dec) -}}
{{- end -}}
{{- if eq $value "" -}}
{{- if and $autoGenerate $managedSecretEnabled -}}
{{- $value = (randAlphaNum 64 | sha256sum) -}}
{{- else -}}
{{- fail (printf "doublePuppet.registration.%s is required (set doublePuppet.registration.%s, provide existingSecret, or enable auto-generation with managed secret mode)" $key $key) -}}
{{- end -}}
{{- end -}}
{{- $_ := set $computed $key $value -}}
{{- end -}}

{{- $_ := set $doublePuppet "_computedRegistration" $computed -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRegistrationValue" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- include "mautrix-go-base.ensureDoublePuppetRegistrationData" $root -}}
{{- $doublePuppet := $root.Values.doublePuppet | default dict -}}
{{- $computed := (get $doublePuppet "_computedRegistration") | default dict -}}
{{- if not (hasKey $computed $key) -}}
{{- fail (printf "computed doublePuppet registration values missing key %q" $key) -}}
{{- end -}}
{{- index $computed $key -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetReuseFound" -}}
{{- include "mautrix-go-base.ensureDoublePuppetRegistrationData" . -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $computed := (get $doublePuppet "_computedRegistration") | default dict -}}
{{- if (get $computed "reuseFound") -}}true{{- else -}}false{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetShouldRenderPrimaryConfigMap" -}}
{{- if ne (include "mautrix-go-base.doublePuppetEnabled" .) "true" -}}
false
{{- else -}}
{{- include "mautrix-go-base.ensureDoublePuppetRegistrationData" . -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $computed := (get $doublePuppet "_computedRegistration") | default dict -}}
{{- $reuseFound := (get $computed "reuseFound") | default false -}}
{{- $reuseNamespace := (get $computed "reuseNamespace") | default .Release.Namespace -}}
{{- $reuseConfigMapName := (get $computed "reuseConfigMapName") | default "" -}}
{{- $targetConfigMapName := include "mautrix-go-base.doublePuppetRegistrationConfigMapName" . -}}
{{- if and $reuseFound (eq $reuseNamespace .Release.Namespace) (eq $reuseConfigMapName $targetConfigMapName) -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetShouldRenderSynapseConfigMap" -}}
{{- if ne (include "mautrix-go-base.doublePuppetEnabled" .) "true" -}}
false
{{- else -}}
{{- $synapseNamespace := .Values.registration.synapseNamespace | default "" | trim -}}
{{- if or (eq $synapseNamespace "") (eq $synapseNamespace .Release.Namespace) -}}
false
{{- else if eq (include "mautrix-go-base.doublePuppetReuseFound" .) "true" -}}
false
{{- else -}}
true
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRegistrationConfig" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
{{- $registration := (get $doublePuppet "registration") | default dict -}}
id: {{ include "mautrix-go-base.doublePuppetRegistrationID" . | quote }}
url: null
as_token: {{ include "mautrix-go-base.doublePuppetRegistrationValue" (dict "root" . "key" "asToken") | quote }}
hs_token: {{ include "mautrix-go-base.doublePuppetRegistrationValue" (dict "root" . "key" "hsToken") | quote }}
sender_localpart: {{ include "mautrix-go-base.doublePuppetRegistrationValue" (dict "root" . "key" "senderLocalpart") | quote }}
rate_limited: {{ if hasKey $registration "rateLimited" }}{{ get $registration "rateLimited" }}{{ else }}false{{ end }}
namespaces:
  users:
    - exclusive: false
      regex: {{ include "mautrix-go-base.doublePuppetUserRegex" . | squote }}
{{- end -}}

{{- define "mautrix-go-base.parseYamlMap" -}}
{{- $field := required "mautrix-go-base.parseYamlMap: field is required" .field -}}
{{- $raw := .value | default "" | trim -}}
{{- if eq $raw "" -}}
{}
{{- else -}}
{{- $parsed := fromYaml $raw -}}
{{- if and (kindIs "map" $parsed) (hasKey $parsed "Error") -}}
{{- fail (printf "%s must be valid YAML mapping (object) at the top level" $field) -}}
{{- end -}}
{{- if not (kindIs "map" $parsed) -}}
{{- fail (printf "%s must be a YAML mapping (object) at the top level" $field) -}}
{{- end -}}
{{ toYaml $parsed }}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.pathConflictsWithReserved" -}}
{{- $data := .data | default dict -}}
{{- $path := .path | default "" | trim -}}
{{- if eq $path "" -}}
false
{{- else -}}
{{- $parts := splitList "." $path -}}
{{- $state := dict "current" $data "conflict" false -}}
{{- range $idx, $part := $parts -}}
{{- if not (get $state "conflict") -}}
{{- $current := get $state "current" -}}
{{- if not (kindIs "map" $current) -}}
{{- $_ := set $state "conflict" true -}}
{{- else if hasKey $current $part -}}
{{- if eq $idx (sub (len $parts) 1) -}}
{{- $_ := set $state "conflict" true -}}
{{- else -}}
{{- $_ := set $state "current" (index $current $part) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- if get $state "conflict" -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.validateReservedPaths" -}}
{{- $data := .data | default dict -}}
{{- $field := required "mautrix-go-base.validateReservedPaths: field is required" .field -}}
{{- $pathsRaw := .paths | default "" -}}
{{- $displayPrefix := .displayPrefix | default "" -}}
{{- $hint := .hint | default "use first-class values instead" -}}
{{- $paths := splitList "," (replace "\n" "," $pathsRaw) -}}
{{- range $idx, $pathValue := $paths -}}
{{- $path := $pathValue | trim -}}
{{- if ne $path "" -}}
{{- $conflicts := include "mautrix-go-base.pathConflictsWithReserved" (dict "data" $data "path" $path) -}}
{{- if eq $conflicts "true" -}}
{{- fail (printf "%s cannot set %s%s; %s" $field $displayPrefix $path $hint) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.bridgev2MergedConfig" -}}
{{- $config := .Values.config | default dict -}}
{{- $baseExtra := fromYaml (include "mautrix-go-base.parseYamlMap" (dict
  "field" "values.config.baseExtra"
  "value" ((get $config "baseExtra") | default "")
)) -}}
{{- $networkExtra := fromYaml (include "mautrix-go-base.parseYamlMap" (dict
  "field" "values.config.networkExtra"
  "value" ((get $config "networkExtra") | default "")
)) -}}

{{- if hasKey $baseExtra "network" -}}
{{- fail "values.config.baseExtra cannot set network; use values.config.networkExtra for bridge-specific network config" -}}
{{- end -}}
{{- if hasKey $baseExtra "logging" -}}
{{- fail "values.config.baseExtra cannot set logging; use values.logging instead" -}}
{{- end -}}
{{- if hasKey $networkExtra "network" -}}
{{- fail "values.config.networkExtra must contain raw network keys, not a nested network block" -}}
{{- end -}}
{{- if and (eq (include "mautrix-go-base.doublePuppetEnabled" .) "true") (hasKey $baseExtra "double_puppet") -}}
{{- $doublePuppetCfg := index $baseExtra "double_puppet" -}}
{{- if not (kindIs "map" $doublePuppetCfg) -}}
{{- fail "values.config.baseExtra.double_puppet must be a YAML mapping when set" -}}
{{- end -}}
{{- if hasKey $doublePuppetCfg "secrets" -}}
{{- $doublePuppetSecrets := index $doublePuppetCfg "secrets" -}}
{{- if not (kindIs "map" $doublePuppetSecrets) -}}
{{- fail "values.config.baseExtra.double_puppet.secrets must be a YAML mapping when set" -}}
{{- end -}}
{{- $homeserverDomain := include "mautrix-go-base.homeserverDomain" . -}}
{{- if hasKey $doublePuppetSecrets $homeserverDomain -}}
{{- fail (printf "values.config.baseExtra.double_puppet.secrets cannot set %s; local homeserver double puppeting is managed by Helm" $homeserverDomain) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- include "mautrix-go-base.validateReservedPaths" (dict
  "data" $baseExtra
  "field" "values.config.baseExtra"
  "paths" (include (printf "%s.reservedBasePaths" .Chart.Name) .)
  "hint" "use first-class values instead"
) -}}
{{- include "mautrix-go-base.validateReservedPaths" (dict
  "data" $networkExtra
  "field" "values.config.networkExtra"
  "paths" (include (printf "%s.reservedNetworkPaths" .Chart.Name) .)
  "displayPrefix" "network."
  "hint" "use first-class values instead"
) -}}

{{- $managedRaw := include (printf "%s.managedConfig" .Chart.Name) . -}}
{{- $managed := fromYaml $managedRaw -}}
{{- if and (kindIs "map" $managed) (hasKey $managed "Error") -}}
{{- fail (printf "%s.managedConfig must render valid YAML mapping" .Chart.Name) -}}
{{- end -}}
{{- if not (kindIs "map" $managed) -}}
{{- fail (printf "%s.managedConfig must render a YAML mapping" .Chart.Name) -}}
{{- end -}}

{{- $logLevel := (.Values.logging | default "info" | toString | lower) -}}
{{- $allowedLevels := list "panic" "fatal" "error" "warn" "info" "debug" "trace" -}}
{{- if not (has $logLevel $allowedLevels) -}}
{{- fail "values.logging must be one of: panic, fatal, error, warn, info, debug, trace" -}}
{{- end -}}
{{- $managedLogging := dict
  "logging" (dict
    "min_level" $logLevel
    "writers" (list (dict
      "type" "stdout"
      "format" "pretty-colored"
    ))
  )
-}}

{{- $managedDoublePuppet := dict -}}
{{- if eq (include "mautrix-go-base.doublePuppetEnabled" .) "true" -}}
{{- $homeserverDomain := include "mautrix-go-base.homeserverDomain" . -}}
{{- $managedDoublePuppet = dict
  "double_puppet" (dict
    "secrets" (dict
      $homeserverDomain (printf "as_token:%s" (include "mautrix-go-base.doublePuppetRegistrationValue" (dict "root" . "key" "asToken"))
      )
    )
  )
-}}
{{- end -}}

{{- $networkBlock := dict -}}
{{- if gt (len $networkExtra) 0 -}}
{{- $networkBlock = dict "network" $networkExtra -}}
{{- end -}}

{{- $merged := mustMergeOverwrite (dict) $baseExtra $networkBlock $managed $managedLogging $managedDoublePuppet -}}
{{ toYaml $merged }}
{{- end -}}

{{- define "mautrix-go-base.ensureRuntimeSecrets" -}}
{{- if not (hasKey .Values.registration "_computedRuntimeSecrets") -}}
{{- $keysRaw := include (printf "%s.runtimeSecretKeys" .Chart.Name) . | trim -}}
{{- if eq $keysRaw "" -}}
{{- fail (printf "%s.runtimeSecretKeys must render a comma-separated list of registration key names" .Chart.Name) -}}
{{- end -}}
{{- $keys := splitList "," $keysRaw -}}
{{- $useExistingSecret := ne (.Values.registration.existingSecret | default "") "" -}}
{{- $managedSecret := .Values.registration.managedSecret | default dict -}}
{{- $managedSecretEnabled := and (not $useExistingSecret) ((get $managedSecret "enabled") | default false) -}}
{{- $secretName := include "mautrix-go-base.runtimeSecretName" . -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- $computed := dict -}}
{{- range $idx, $key := $keys -}}
{{- $secretKey := $key | trim -}}
{{- if eq $secretKey "" -}}
{{- fail (printf "%s.runtimeSecretKeys[%d] must not be empty" $.Chart.Name $idx) -}}
{{- end -}}
{{- $value := (get $.Values.registration $secretKey) | default "" -}}
{{- if eq $value "generate" -}}
{{- fail (printf "values.registration.%s must not be set to 'generate'; leave empty for auto-generation" $secretKey) -}}
{{- end -}}
{{- if and (eq $value "") $existing (hasKey $existing.data $secretKey) -}}
{{- $value = (index $existing.data $secretKey | b64dec) -}}
{{- end -}}
{{- if eq $value "" -}}
{{- if and $.Values.registration.autoGenerate $managedSecretEnabled -}}
{{- $value = (randAlphaNum 64 | sha256sum) -}}
{{- else -}}
{{- fail (printf "registration.%s is required when missing from secret %q (set registration.%s, set registration.existingSecret to a populated Secret, or enable registration.autoGenerate with registration.managedSecret.enabled=true)" $secretKey $secretName $secretKey) -}}
{{- end -}}
{{- end -}}
{{- $_ := set $computed $secretKey $value -}}
{{- end -}}
{{- $_ := set .Values.registration "_computedRuntimeSecrets" $computed -}}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.runtimeSecretValue" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- include "mautrix-go-base.ensureRuntimeSecrets" $root -}}
{{- $computed := index $root.Values.registration "_computedRuntimeSecrets" -}}
{{- if not (hasKey $computed $key) -}}
{{- fail (printf "computed runtime secrets missing key %q" $key) -}}
{{- end -}}
{{- index $computed $key -}}
{{- end -}}

{{- define "mautrix-go-base.registrationConfig" -}}
id: {{ .Values.appservice.id | quote }}
url: {{ include "mautrix-go-base.registrationServiceUrl" . | quote }}
as_token: {{ include "mautrix-go-base.runtimeSecretValue" (dict "root" . "key" "asToken") | quote }}
hs_token: {{ include "mautrix-go-base.runtimeSecretValue" (dict "root" . "key" "hsToken") | quote }}
sender_localpart: {{ include "mautrix-go-base.registrationSenderLocalpart" . | quote }}
rate_limited: {{ .Values.registration.rateLimited }}
namespaces:
  users:
    - exclusive: true
      regex: {{ include "mautrix-go-base.registrationUserRegex" . | squote }}
{{- end -}}
