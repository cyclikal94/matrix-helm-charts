{{- define "baibot.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "baibot.fullname" -}}
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

{{- define "baibot.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "baibot.selectorLabels" -}}
app.kubernetes.io/name: {{ include "baibot.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "baibot.name" . }}
{{- end -}}

{{- define "baibot.labels" -}}
helm.sh/chart: {{ include "baibot.chart" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{ include "baibot.selectorLabels" . }}
{{- end -}}

{{- define "baibot.image" -}}
{{- if .Values.image.tag -}}
{{- printf "%s:%s" .Values.image.repository .Values.image.tag -}}
{{- else -}}
{{- .Values.image.repository -}}
{{- end -}}
{{- end -}}

{{- define "baibot.configSecretName" -}}
{{- printf "%s-config" (include "baibot.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "baibot.runtimeSupportSecretName" -}}
{{- printf "%s-runtime-support" (include "baibot.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "baibot.parseYamlMap" -}}
{{- $raw := .raw | default "" -}}
{{- $description := .description -}}
{{- if eq $raw "" -}}
{}
{{- else -}}
{{- $parsed := fromYaml $raw -}}
{{- if and $parsed (hasKey $parsed "Error") -}}
{{- fail (printf "%s must be valid YAML: %s" $description (get $parsed "Error")) -}}
{{- end -}}
{{- if and $parsed (not (kindIs "map" $parsed)) -}}
{{- fail (printf "%s must be a YAML mapping (object) at the top level" $description) -}}
{{- end -}}
{{- if $parsed -}}
{{ toYaml $parsed }}
{{- else -}}
{}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "baibot.userFragment" -}}
{{- $user := .Values.user | default dict -}}
{{- if eq ((get $user "existingSecret") | default "") "" -}}
{}
{{- else -}}
{{- $secretName := ((get $user "existingSecret") | default "") -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if not $secret -}}
{{- fail (printf "user.existingSecret secret %q was not found in namespace %q" $secretName .Release.Namespace) -}}
{{- end -}}
{{- $data := $secret.data | default dict -}}
{{- $fragment := dict -}}
{{- if hasKey $data "password" -}}
{{- $_ := set $fragment "password" (index $data "password" | b64dec) -}}
{{- end -}}
{{- if hasKey $data "accessToken" -}}
{{- $_ := set $fragment "access_token" (index $data "accessToken" | b64dec) -}}
{{- end -}}
{{- if hasKey $data "deviceId" -}}
{{- $_ := set $fragment "device_id" (index $data "deviceId" | b64dec) -}}
{{- end -}}
{{- $encryption := dict -}}
{{- if hasKey $data "recoveryPassphrase" -}}
{{- $_ := set $encryption "recovery_passphrase" (index $data "recoveryPassphrase" | b64dec) -}}
{{- end -}}
{{- if hasKey $data "recoveryResetAllowed" -}}
{{- $value := (index $data "recoveryResetAllowed" | b64dec | trim | lower) -}}
{{- if eq $value "true" -}}
{{- $_ := set $encryption "recovery_reset_allowed" true -}}
{{- else if eq $value "false" -}}
{{- $_ := set $encryption "recovery_reset_allowed" false -}}
{{- else -}}
{{- fail (printf "user.existingSecret secret %q key %q must be either 'true' or 'false'" $secretName "recoveryResetAllowed") -}}
{{- end -}}
{{- end -}}
{{- if gt (len $encryption) 0 -}}
{{- $_ := set $fragment "encryption" $encryption -}}
{{- end -}}
{{ toYaml $fragment }}
{{- end -}}
{{- end -}}

{{- define "baibot.persistenceFragment" -}}
{{- $persistence := .Values.persistence | default dict -}}
{{- if eq ((get $persistence "existingSecret") | default "") "" -}}
{}
{{- else -}}
{{- $secretName := ((get $persistence "existingSecret") | default "") -}}
{{- $secret := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if not $secret -}}
{{- fail (printf "persistence.existingSecret secret %q was not found in namespace %q" $secretName .Release.Namespace) -}}
{{- end -}}
{{- $data := $secret.data | default dict -}}
{{- $fragment := dict -}}
{{- if hasKey $data "sessionEncryptionKey" -}}
{{- $_ := set $fragment "session_encryption_key" (index $data "sessionEncryptionKey" | b64dec) -}}
{{- end -}}
{{- if hasKey $data "configEncryptionKey" -}}
{{- $_ := set $fragment "config_encryption_key" (index $data "configEncryptionKey" | b64dec) -}}
{{- end -}}
{{ toYaml $fragment }}
{{- end -}}
{{- end -}}

{{- define "baibot.ensureComputedConfig" -}}
{{- if not (hasKey .Values "_baibotComputed") -}}
{{- $userValues := .Values.user | default dict -}}
{{- $persistenceValues := .Values.persistence | default dict -}}
{{- $agentsValues := .Values.agents | default dict -}}
{{- $agentApiKeysValues := (get $agentsValues "apiKeys") | default dict -}}
{{- $persistenceEnabled := true -}}
{{- if hasKey $persistenceValues "enabled" -}}
{{- $persistenceEnabled = (get $persistenceValues "enabled") -}}
{{- end -}}
{{- $config := include "baibot.parseYamlMap" (dict "raw" .Values.config.extra "description" "values.config.extra") | fromYaml -}}
{{- if not $config }}{{- $config = dict -}}{{- end -}}

{{- if hasKey $config "user" -}}
{{- if not (kindIs "map" (index $config "user")) -}}
{{- fail "values.config.extra.user must be a YAML mapping when set" -}}
{{- end -}}
{{- end -}}
{{- if hasKey $config "persistence" -}}
{{- if not (kindIs "map" (index $config "persistence")) -}}
{{- fail "values.config.extra.persistence must be a YAML mapping when set" -}}
{{- end -}}
{{- end -}}
{{- if hasKey $config "agents" -}}
{{- if not (kindIs "map" (index $config "agents")) -}}
{{- fail "values.config.extra.agents must be a YAML mapping when set" -}}
{{- end -}}
{{- end -}}
{{- if hasKey $config "homeserver" -}}
{{- if not (kindIs "map" (index $config "homeserver")) -}}
{{- fail "values.config.extra.homeserver must be a YAML mapping when set" -}}
{{- end -}}
{{- end -}}
{{- if hasKey $config "access" -}}
{{- if not (kindIs "map" (index $config "access")) -}}
{{- fail "values.config.extra.access must be a YAML mapping when set" -}}
{{- end -}}
{{- end -}}
{{- if hasKey $config "initial_global_config" -}}
{{- if not (kindIs "map" (index $config "initial_global_config")) -}}
{{- fail "values.config.extra.initial_global_config must be a YAML mapping when set" -}}
{{- end -}}
{{- end -}}

{{- $configUser := (get $config "user") | default dict -}}
{{- $configUserEncryption := dict -}}
{{- if and (hasKey $configUser "encryption") (not (kindIs "map" (index $configUser "encryption"))) -}}
{{- fail "values.config.extra.user.encryption must be a YAML mapping when set" -}}
{{- else if hasKey $configUser "encryption" -}}
{{- $configUserEncryption = index $configUser "encryption" -}}
{{- end -}}

{{- $configPersistence := (get $config "persistence") | default dict -}}
{{- $configAgents := (get $config "agents") | default dict -}}
{{- $userFragment := include "baibot.userFragment" . | fromYaml -}}
{{- $persistenceFragment := include "baibot.persistenceFragment" . | fromYaml -}}

{{- if hasKey $configPersistence "data_dir_path" -}}
{{- fail "values.config.extra cannot set persistence.data_dir_path; it is always managed by the chart and fixed to /data" -}}
{{- end -}}

{{- $manageUserPassword := or (ne ((get $userValues "password") | default "") "") (hasKey $userFragment "password") -}}
{{- $manageUserAccessToken := or (ne ((get $userValues "accessToken") | default "") "") (hasKey $userFragment "access_token") -}}
{{- $manageUserDeviceId := or (ne ((get $userValues "deviceId") | default "") "") (hasKey $userFragment "device_id") -}}
{{- $manageUserRecoveryPassphrase := or (ne ((get $userValues "recoveryPassphrase") | default "") "") (and (hasKey $userFragment "encryption") (hasKey (index $userFragment "encryption") "recovery_passphrase")) -}}
{{- $userHasRecoveryResetAllowed := hasKey $userValues "recoveryResetAllowed" -}}
{{- $manageUserRecoveryResetAllowed := or $userHasRecoveryResetAllowed (and (hasKey $userFragment "encryption") (hasKey (index $userFragment "encryption") "recovery_reset_allowed")) -}}

{{- if and $manageUserPassword (hasKey $configUser "password") -}}
{{- fail "values.config.extra cannot set user.password when it is managed by Helm via user.password or user.existingSecret" -}}
{{- end -}}
{{- if and $manageUserAccessToken (hasKey $configUser "access_token") -}}
{{- fail "values.config.extra cannot set user.access_token when it is managed by Helm via user.accessToken or user.existingSecret" -}}
{{- end -}}
{{- if and $manageUserDeviceId (hasKey $configUser "device_id") -}}
{{- fail "values.config.extra cannot set user.device_id when it is managed by Helm via user.deviceId or user.existingSecret" -}}
{{- end -}}
{{- if and $manageUserRecoveryPassphrase (hasKey $configUserEncryption "recovery_passphrase") -}}
{{- fail "values.config.extra cannot set user.encryption.recovery_passphrase when it is managed by Helm via user.recoveryPassphrase or user.existingSecret" -}}
{{- end -}}
{{- if and $manageUserRecoveryResetAllowed (hasKey $configUserEncryption "recovery_reset_allowed") -}}
{{- fail "values.config.extra cannot set user.encryption.recovery_reset_allowed when it is managed by Helm via user.recoveryResetAllowed or user.existingSecret" -}}
{{- end -}}

{{- $managePersistenceSession := or (ne ((get $persistenceValues "sessionEncryptionKey") | default "") "") (hasKey $persistenceFragment "session_encryption_key") -}}
{{- $managePersistenceConfig := or (ne ((get $persistenceValues "configEncryptionKey") | default "") "") (hasKey $persistenceFragment "config_encryption_key") -}}
{{- $configDefinesPersistenceSession := hasKey $configPersistence "session_encryption_key" -}}
{{- $configDefinesPersistenceConfig := hasKey $configPersistence "config_encryption_key" -}}
{{- $autoManagePersistenceSession := and $persistenceEnabled (not $managePersistenceSession) (not $configDefinesPersistenceSession) -}}
{{- $autoManagePersistenceConfig := and $persistenceEnabled (not $managePersistenceConfig) (not $configDefinesPersistenceConfig) -}}

{{- if and $managePersistenceSession $configDefinesPersistenceSession -}}
{{- fail "values.config.extra cannot set persistence.session_encryption_key when it is managed by Helm via persistence.sessionEncryptionKey or persistence.existingSecret" -}}
{{- end -}}
{{- if and $managePersistenceConfig $configDefinesPersistenceConfig -}}
{{- fail "values.config.extra cannot set persistence.config_encryption_key when it is managed by Helm via persistence.configEncryptionKey or persistence.existingSecret" -}}
{{- end -}}

{{- $supportSecretName := include "baibot.runtimeSupportSecretName" . -}}
{{- $supportSecret := (lookup "v1" "Secret" .Release.Namespace $supportSecretName) | default dict -}}
{{- $supportData := (get $supportSecret "data") | default dict -}}
{{- $sessionValue := "" -}}
{{- if hasKey $persistenceFragment "session_encryption_key" -}}
{{- $sessionValue = (index $persistenceFragment "session_encryption_key") | default "" -}}
{{- else if ne ((get $persistenceValues "sessionEncryptionKey") | default "") "" -}}
{{- $sessionValue = (get $persistenceValues "sessionEncryptionKey") -}}
{{- else if and $autoManagePersistenceSession (hasKey $supportData "sessionEncryptionKey") -}}
{{- $sessionValue = (index $supportData "sessionEncryptionKey" | b64dec) -}}
{{- else if $autoManagePersistenceSession -}}
{{- $sessionValue = (randAlphaNum 64 | sha256sum) -}}
{{- end -}}

{{- $configValue := "" -}}
{{- if hasKey $persistenceFragment "config_encryption_key" -}}
{{- $configValue = (index $persistenceFragment "config_encryption_key") | default "" -}}
{{- else if ne ((get $persistenceValues "configEncryptionKey") | default "") "" -}}
{{- $configValue = (get $persistenceValues "configEncryptionKey") -}}
{{- else if and $autoManagePersistenceConfig (hasKey $supportData "configEncryptionKey") -}}
{{- $configValue = (index $supportData "configEncryptionKey" | b64dec) -}}
{{- else if $autoManagePersistenceConfig -}}
{{- $configValue = (randAlphaNum 64 | sha256sum) -}}
{{- end -}}

{{- $userOverride := dict -}}
{{- if $manageUserPassword -}}
{{- $_ := set $userOverride "password" (ternary (get $userValues "password") (index $userFragment "password") (ne ((get $userValues "password") | default "") "")) -}}
{{- end -}}
{{- if $manageUserAccessToken -}}
{{- $_ := set $userOverride "access_token" (ternary (get $userValues "accessToken") (index $userFragment "access_token") (ne ((get $userValues "accessToken") | default "") "")) -}}
{{- end -}}
{{- if $manageUserDeviceId -}}
{{- $_ := set $userOverride "device_id" (ternary (get $userValues "deviceId") (index $userFragment "device_id") (ne ((get $userValues "deviceId") | default "") "")) -}}
{{- end -}}
{{- $userEncryptionOverride := dict -}}
{{- if $manageUserRecoveryPassphrase -}}
{{- $_ := set $userEncryptionOverride "recovery_passphrase" (ternary (get $userValues "recoveryPassphrase") (index (index $userFragment "encryption") "recovery_passphrase") (ne ((get $userValues "recoveryPassphrase") | default "") "")) -}}
{{- end -}}
{{- if $manageUserRecoveryResetAllowed -}}
{{- if $userHasRecoveryResetAllowed -}}
{{- $_ := set $userEncryptionOverride "recovery_reset_allowed" (get $userValues "recoveryResetAllowed") -}}
{{- else -}}
{{- $_ := set $userEncryptionOverride "recovery_reset_allowed" (index (index $userFragment "encryption") "recovery_reset_allowed") -}}
{{- end -}}
{{- end -}}
{{- if gt (len $userEncryptionOverride) 0 -}}
{{- $_ := set $userOverride "encryption" $userEncryptionOverride -}}
{{- end -}}

{{- $persistenceOverride := dict "data_dir_path" "/data" -}}
{{- if hasKey $persistenceFragment "session_encryption_key" -}}
{{- $_ := set $persistenceOverride "session_encryption_key" (index $persistenceFragment "session_encryption_key") -}}
{{- end -}}
{{- if hasKey $persistenceFragment "config_encryption_key" -}}
{{- $_ := set $persistenceOverride "config_encryption_key" (index $persistenceFragment "config_encryption_key") -}}
{{- end -}}
{{- if ne ((get $persistenceValues "sessionEncryptionKey") | default "") "" -}}
{{- $_ := set $persistenceOverride "session_encryption_key" (get $persistenceValues "sessionEncryptionKey") -}}
{{- else if $autoManagePersistenceSession -}}
{{- $_ := set $persistenceOverride "session_encryption_key" $sessionValue -}}
{{- end -}}
{{- if ne ((get $persistenceValues "configEncryptionKey") | default "") "" -}}
{{- $_ := set $persistenceOverride "config_encryption_key" (get $persistenceValues "configEncryptionKey") -}}
{{- else if $autoManagePersistenceConfig -}}
{{- $_ := set $persistenceOverride "config_encryption_key" $configValue -}}
{{- end -}}

{{- $mergedUser := mustMergeOverwrite (dict) $configUser $userFragment $userOverride -}}
{{- $mergedPersistence := mustMergeOverwrite (dict) $configPersistence $persistenceFragment $persistenceOverride -}}
{{- $_ := set $config "user" $mergedUser -}}
{{- $_ := set $config "persistence" $mergedPersistence -}}

{{- if hasKey $config "homeserver" -}}
{{- $homeserver := index $config "homeserver" -}}
{{- if or (eq ((get $homeserver "server_name") | default "") "") (eq ((get $homeserver "url") | default "") "") -}}
{{- fail "the generated baibot config requires homeserver.server_name and homeserver.url (set them in values.config.extra)" -}}
{{- end -}}
{{- else -}}
{{- fail "the generated baibot config requires a homeserver mapping in values.config.extra" -}}
{{- end -}}

{{- if eq ((get $mergedUser "mxid_localpart") | default "") "" -}}
{{- fail "the generated baibot config requires user.mxid_localpart (set it in values.config.extra)" -}}
{{- end -}}

{{- $password := (get $mergedUser "password") | default "" -}}
{{- $accessToken := (get $mergedUser "access_token") | default "" -}}
{{- $deviceId := (get $mergedUser "device_id") | default "" -}}
{{- if and (ne $password "") (ne $accessToken "") -}}
{{- fail "the generated baibot config must set exactly one auth method: user.password or user.access_token + user.device_id" -}}
{{- end -}}
{{- if and (eq $password "") (eq $accessToken "") -}}
{{- fail "the generated baibot config must set one auth method: user.password or user.access_token + user.device_id" -}}
{{- end -}}
{{- if and (ne $accessToken "") (eq $deviceId "") -}}
{{- fail "the generated baibot config requires user.device_id when user.access_token is set" -}}
{{- end -}}

{{- if hasKey $config "access" -}}
{{- $access := index $config "access" -}}
{{- $adminPatterns := (get $access "admin_patterns") | default list -}}
{{- if not (kindIs "slice" $adminPatterns) -}}
{{- fail "values.config.extra.access.admin_patterns must be a YAML list" -}}
{{- end -}}
{{- if eq (len $adminPatterns) 0 -}}
{{- fail "the generated baibot config requires at least one access.admin_patterns entry" -}}
{{- end -}}
{{- else -}}
{{- fail "the generated baibot config requires an access mapping in values.config.extra" -}}
{{- end -}}

{{- if not (hasKey $config "initial_global_config") -}}
{{- fail "the generated baibot config requires initial_global_config in values.config.extra" -}}
{{- end -}}

{{- if and (hasKey $configAgents "static_definitions") (not (kindIs "slice" (index $configAgents "static_definitions"))) -}}
{{- fail "values.config.extra.agents.static_definitions must be a YAML list when set" -}}
{{- end -}}

{{- if ne ((get $agentApiKeysValues "existingSecret") | default "") "" -}}
{{- $agentSecret := lookup "v1" "Secret" .Release.Namespace ((get $agentApiKeysValues "existingSecret") | default "") -}}
{{- if not $agentSecret -}}
{{- fail (printf "agents.apiKeys.existingSecret secret %q was not found in namespace %q" ((get $agentApiKeysValues "existingSecret") | default "") .Release.Namespace) -}}
{{- end -}}
{{- $agentSecretData := $agentSecret.data | default dict -}}
{{- if hasKey $config "agents" -}}
{{- $agents := index $config "agents" -}}
{{- $definitions := (get $agents "static_definitions") | default list -}}
{{- range $idx, $agent := $definitions -}}
{{- if not (kindIs "map" $agent) -}}
{{- fail (printf "values.config.extra.agents.static_definitions[%d] must be a YAML mapping" $idx) -}}
{{- end -}}
{{- $agentId := (get $agent "id") | default "" -}}
{{- if and (ne $agentId "") (hasKey $agentSecretData $agentId) -}}
{{- $agentConfig := (get $agent "config") | default dict -}}
{{- if and (hasKey $agent "config") (not (kindIs "map" $agentConfig)) -}}
{{- fail (printf "values.config.extra.agents.static_definitions[%d].config must be a YAML mapping when set" $idx) -}}
{{- end -}}
{{- if and (hasKey $agentConfig "api_key") (ne ((get $agentConfig "api_key") | default "") "") -}}
{{- fail (printf "values.config.extra.agents.static_definitions[%d].config.api_key must not be set when agents.apiKeys.existingSecret provides a key for agent id %q" $idx $agentId) -}}
{{- end -}}
{{- if not (hasKey $agent "config") -}}
{{- $_ := set $agent "config" (dict) -}}
{{- $agentConfig = index $agent "config" -}}
{{- end -}}
{{- $_ := set $agentConfig "api_key" (index $agentSecretData $agentId | b64dec) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- $_ := set .Values "_baibotComputed" (dict
  "config" $config
  "persistenceSupportSecret" (dict
    "sessionManaged" $autoManagePersistenceSession
    "configManaged" $autoManagePersistenceConfig
    "sessionValue" $sessionValue
    "configValue" $configValue
  )
) -}}
{{- end -}}
{{- end -}}

{{- define "baibot.computedConfig" -}}
{{- include "baibot.ensureComputedConfig" . -}}
{{- toYaml (index (index .Values "_baibotComputed") "config") -}}
{{- end -}}

{{- define "baibot.persistenceSupportSecretData" -}}
{{- include "baibot.ensureComputedConfig" . -}}
{{- $support := index (index .Values "_baibotComputed") "persistenceSupportSecret" -}}
{{- if or (index $support "sessionManaged") (index $support "configManaged") -}}
{{ toYaml $support }}
{{- else -}}
{}
{{- end -}}
{{- end -}}
