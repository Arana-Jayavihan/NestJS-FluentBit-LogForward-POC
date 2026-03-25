# FluentBit Helm Chart values (Terraform template)

kind: Deployment
replicaCount: ${replica_count}

image:
  repository: cr.fluentbit.io/fluent/fluent-bit
  tag: "${image_tag}"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 2020
  annotations: {}

# Expose TCP input port for receiving logs from NestJS app
extraPorts:
  - port: ${tcp_port}
    containerPort: ${tcp_port}
    protocol: TCP
    name: tcp-input

# Mount the secrets ConfigMap
extraVolumes:
  - name: fluentbit-secrets
    configMap:
      name: fluentbit-secrets

extraVolumeMounts:
  - name: fluentbit-secrets
    mountPath: /fluent-bit/secrets
    readOnly: true

# FluentBit configuration
config:
  service: |
    [SERVICE]
        Daemon Off
        Flush 1
        Log_Level info
        Parsers_File /fluent-bit/etc/parsers.conf
        HTTP_Server On
        HTTP_Listen 0.0.0.0
        HTTP_Port 2020
        Health_Check On

  inputs: |
    [INPUT]
        Name tcp
        Listen 0.0.0.0
        Port ${tcp_port}
        Chunk_Size 32
        Buffer_Size 64
        Format json
        Tag app.logs

  filters: |
    [FILTER]
        Name modify
        Match *
        Rename time CreatedTime

  outputs: |
    [OUTPUT]
        Name stdout
        Match *
        Format json_lines

    [OUTPUT]
        Name file
        Match *
        Path /tmp
        File out.log
%{ if azure_enabled }

    [OUTPUT]
        Name azure_logs_ingestion
        Match *
        client_id ${azure_client_id}
        client_secret ${azure_client_secret}
        tenant_id ${azure_tenant_id}
        dce_url ${azure_dce_url}
        dcr_id ${azure_dcr_id}
        table_name ${azure_table_name}
        time_generated false
        time_key CreatedTime
        Compress gzip
%{ endif }

# Environment variables from ConfigMap (for Azure secrets)
envFrom:
  - configMapRef:
      name: fluentbit-secrets
      optional: true

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Disable daemonset-specific features
daemonSetVolumes: []
daemonSetVolumeMounts: []

# Pod settings
podAnnotations: {}
podLabels: {}

tolerations: []
affinity: {}
nodeSelector: {}
