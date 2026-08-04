{{- define "mautrix-go-base.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "mautrix-go-base.fullname" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "bridge") | nindent 4 }}
spec:
  publishNotReadyAddresses: {{ .Values.service.publishNotReadyAddresses }}
  selector:
    {{- include "mautrix-go-base.componentSelectorLabels" (dict "context" . "component" "bridge") | nindent 4 }}
  ports:
    - name: appservice
      protocol: TCP
      port: {{ .Values.service.port }}
      targetPort: appservice
{{- end -}}

{{- define "mautrix-go-base.statefulset" -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "mautrix-go-base.fullname" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "bridge") | nindent 4 }}
spec:
  serviceName: {{ include "mautrix-go-base.fullname" . }}
  replicas: 1
  selector:
    matchLabels:
      {{- include "mautrix-go-base.componentSelectorLabels" (dict "context" . "component" "bridge") | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "mautrix-go-base.componentSelectorLabels" (dict "context" . "component" "bridge") | nindent 8 }}
      annotations:
        checksum/config: {{ include (print $.Template.BasePath "/config-secret.yaml") . | sha256sum }}
        checksum/runtime-secrets: {{ include (print $.Template.BasePath "/runtime-secrets.yaml") . | sha256sum }}
        checksum/doublepuppet-runtime-secrets: {{ include "mautrix-go-base.doublePuppetRuntimeSecret" . | sha256sum }}
    spec:
      {{- if .Values.podSecurityContext.enabled }}
      {{- $podSecurityContext := omit .Values.podSecurityContext "enabled" }}
      {{- with $podSecurityContext.seccompProfile }}
      {{- if ne .type "Localhost" }}
      {{- $podSecurityContext = merge (omit $podSecurityContext "seccompProfile") (dict "seccompProfile" (omit . "localhostProfile")) }}
      {{- end }}
      {{- end }}
      securityContext:
        {{- toYaml $podSecurityContext | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ include "mautrix-go-base.name" . }}
          image: {{ include "mautrix-go-base.image" . }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          command:
            {{- include (printf "%s.bridgeCommand" .Chart.Name) . | nindent 12 }}
          args:
            {{- include (printf "%s.bridgeArgs" .Chart.Name) . | nindent 12 }}
          ports:
            - name: appservice
              containerPort: {{ .Values.appservice.port }}
          {{- if .Values.probes.liveness.enabled }}
          livenessProbe:
            httpGet:
              path: {{ .Values.probes.liveness.path }}
              port: appservice
            initialDelaySeconds: {{ .Values.probes.liveness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.liveness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.liveness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.liveness.failureThreshold }}
          {{- end }}
          {{- if .Values.probes.readiness.enabled }}
          readinessProbe:
            httpGet:
              path: {{ .Values.probes.readiness.path }}
              port: appservice
            initialDelaySeconds: {{ .Values.probes.readiness.initialDelaySeconds }}
            periodSeconds: {{ .Values.probes.readiness.periodSeconds }}
            timeoutSeconds: {{ .Values.probes.readiness.timeoutSeconds }}
            failureThreshold: {{ .Values.probes.readiness.failureThreshold }}
          {{- end }}
          {{- if .Values.securityContext.enabled }}
          securityContext:
            {{- toYaml (omit .Values.securityContext "enabled") | nindent 12 }}
          {{- end }}
          {{- with .Values.bridge.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: bridge-config
              mountPath: /data
              readOnly: true
      volumes:
        - name: bridge-config
          secret:
            secretName: {{ include "mautrix-go-base.configSecretName" . }}
            items:
              - key: config.yaml
                path: config.yaml
{{- end -}}

{{- define "mautrix-go-base.runtimeSecret" -}}
{{- if and (eq (.Values.registration.existingSecret | default "") "") .Values.registration.managedSecret.enabled }}
{{- $keysRaw := include (printf "%s.runtimeSecretKeys" .Chart.Name) . | trim -}}
{{- if eq $keysRaw "" -}}
{{- fail (printf "%s.runtimeSecretKeys must render a comma-separated list of registration key names" .Chart.Name) -}}
{{- end -}}
{{- $keys := splitList "," $keysRaw -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mautrix-go-base.runtimeSecretName" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "registration") | nindent 4 }}
type: Opaque
stringData:
{{- range $idx, $key := $keys }}
{{- $secretKey := $key | trim -}}
{{- if eq $secretKey "" -}}
{{- fail (printf "%s.runtimeSecretKeys[%d] must not be empty" $.Chart.Name $idx) -}}
{{- end }}
  {{ $secretKey }}: {{ include "mautrix-go-base.runtimeSecretValue" (dict "root" $ "key" $secretKey) | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRuntimeSecret" -}}
{{- if eq (include "mautrix-go-base.doublePuppetEnabled" .) "true" -}}
{{- $doublePuppet := .Values.doublePuppet | default dict -}}
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
{{- if $managedSecretEnabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mautrix-go-base.doublePuppetRuntimeSecretName" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "doublepuppet-registration") | nindent 4 }}
type: Opaque
stringData:
  asToken: {{ include "mautrix-go-base.doublePuppetRegistrationValue" (dict "root" . "key" "asToken") | quote }}
  hsToken: {{ include "mautrix-go-base.doublePuppetRegistrationValue" (dict "root" . "key" "hsToken") | quote }}
  senderLocalpart: {{ include "mautrix-go-base.doublePuppetRegistrationValue" (dict "root" . "key" "senderLocalpart") | quote }}
{{- end }}
{{- end -}}
{{- end -}}

{{- define "mautrix-go-base.configSecret" -}}
{{- $configYaml := include (printf "%s.mergedConfig" .Chart.Name) . -}}
{{- $parsed := fromYaml $configYaml -}}
{{- if and $parsed (not (kindIs "map" $parsed)) -}}
{{- fail (printf "%s.mergedConfig must render a YAML mapping" .Chart.Name) -}}
{{- end -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mautrix-go-base.configSecretName" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "bridge") | nindent 4 }}
type: Opaque
stringData:
  config.yaml: |
{{ $configYaml | nindent 4 }}
{{- end -}}

{{- define "mautrix-go-base.registrationConfigMap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mautrix-go-base.registrationConfigMapName" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "registration") | nindent 4 }}
data:
  {{ include (printf "%s.registrationFileKey" .Chart.Name) . }}: |
{{ include (printf "%s.registrationConfig" .Chart.Name) . | indent 4 }}
{{- end -}}

{{- define "mautrix-go-base.synapseRegistrationConfigMap" -}}
{{- $synapseNamespace := .Values.registration.synapseNamespace | default "" | trim -}}
{{- if and $synapseNamespace (ne $synapseNamespace .Release.Namespace) }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mautrix-go-base.registrationConfigMapName" . }}
  namespace: {{ $synapseNamespace }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "registration") | nindent 4 }}
data:
  {{ include (printf "%s.registrationFileKey" .Chart.Name) . }}: |
{{ include (printf "%s.registrationConfig" .Chart.Name) . | indent 4 }}
{{- end }}
{{- end -}}

{{- define "mautrix-go-base.doublePuppetRegistrationConfigMap" -}}
{{- if eq (include "mautrix-go-base.doublePuppetShouldRenderPrimaryConfigMap" .) "true" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mautrix-go-base.doublePuppetRegistrationConfigMapName" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "doublepuppet-registration") | nindent 4 }}
data:
  {{ include "mautrix-go-base.doublePuppetRegistrationFileKey" . }}: |
{{ include "mautrix-go-base.doublePuppetRegistrationConfig" . | indent 4 }}
{{- end }}
{{- end -}}

{{- define "mautrix-go-base.synapseDoublePuppetRegistrationConfigMap" -}}
{{- if eq (include "mautrix-go-base.doublePuppetShouldRenderSynapseConfigMap" .) "true" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "mautrix-go-base.doublePuppetRegistrationConfigMapName" . }}
  namespace: {{ include "mautrix-go-base.doublePuppetSynapseNamespace" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "doublepuppet-registration") | nindent 4 }}
data:
  {{ include "mautrix-go-base.doublePuppetRegistrationFileKey" . }}: |
{{ include "mautrix-go-base.doublePuppetRegistrationConfig" . | indent 4 }}
{{- end }}
{{- end -}}

{{- define "mautrix-go-base.postgresSecret" -}}
{{- if .Values.postgres.enabled }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "mautrix-go-base.postgresFullname" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "postgres") | nindent 4 }}
type: Opaque
stringData:
  password: {{ include "mautrix-go-base.databasePostgresPassword" . | quote }}
{{- end }}
{{- end -}}

{{- define "mautrix-go-base.postgresService" -}}
{{- if .Values.postgres.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "mautrix-go-base.postgresFullname" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "postgres") | nindent 4 }}
spec:
  selector:
    {{- include "mautrix-go-base.componentSelectorLabels" (dict "context" . "component" "postgres") | nindent 4 }}
  ports:
    - name: postgres
      protocol: TCP
      port: {{ .Values.postgres.service.port }}
      targetPort: postgres
{{- end }}
{{- end -}}

{{- define "mautrix-go-base.postgresStatefulSet" -}}
{{- if .Values.postgres.enabled }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "mautrix-go-base.postgresFullname" . }}
  labels:
    {{- include "mautrix-go-base.componentLabels" (dict "context" . "component" "postgres") | nindent 4 }}
spec:
  serviceName: {{ include "mautrix-go-base.postgresFullname" . }}
  replicas: 1
  selector:
    matchLabels:
      {{- include "mautrix-go-base.componentSelectorLabels" (dict "context" . "component" "postgres") | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "mautrix-go-base.componentSelectorLabels" (dict "context" . "component" "postgres") | nindent 8 }}
      annotations:
        checksum/secret: {{ include (print $.Template.BasePath "/postgres-secret.yaml") . | sha256sum }}
    spec:
      {{- if .Values.postgres.podSecurityContext.enabled }}
      {{- $podSecurityContext := omit .Values.postgres.podSecurityContext "enabled" }}
      {{- with $podSecurityContext.seccompProfile }}
      {{- if ne .type "Localhost" }}
      {{- $podSecurityContext = merge (omit $podSecurityContext "seccompProfile") (dict "seccompProfile" (omit . "localhostProfile")) }}
      {{- end }}
      {{- end }}
      securityContext:
        {{- toYaml $podSecurityContext | nindent 8 }}
      {{- end }}
      containers:
        - name: postgres
          image: {{ include "mautrix-go-base.postgresImage" . }}
          imagePullPolicy: {{ .Values.postgres.image.pullPolicy }}
          {{- if .Values.postgres.securityContext.enabled }}
          securityContext:
            {{- toYaml (omit .Values.postgres.securityContext "enabled") | nindent 12 }}
          {{- end }}
          env:
            - name: POSTGRES_DB
              value: {{ include "mautrix-go-base.databasePostgresDatabase" . | quote }}
            - name: POSTGRES_USER
              value: {{ include "mautrix-go-base.databasePostgresUser" . | quote }}
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "mautrix-go-base.postgresFullname" . }}
                  key: password
            # Put the actual data dir in a subpath of the volume mount so the
            # postgres entrypoint's `chmod` succeeds when running as an
            # arbitrary high UID (OpenShift's default SCC). The mount itself
            # is owned root:fsGroup with g+rwx; the subpath is created by
            # postgres at first run with the right perms.
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          ports:
            - name: postgres
              containerPort: {{ .Values.postgres.service.port }}
          volumeMounts:
            - name: data
              mountPath: /var/lib/postgresql/data
          {{- with .Values.postgres.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
      {{- if not .Values.postgres.persistence.enabled }}
      volumes:
        - name: data
          emptyDir: {}
      {{- end }}
  {{- if .Values.postgres.persistence.enabled }}
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes:
          - {{ .Values.postgres.persistence.accessMode }}
        resources:
          requests:
            storage: {{ .Values.postgres.persistence.size }}
        {{- if .Values.postgres.persistence.storageClassName }}
        storageClassName: {{ .Values.postgres.persistence.storageClassName }}
        {{- end }}
  {{- end }}
{{- end }}
{{- end -}}
