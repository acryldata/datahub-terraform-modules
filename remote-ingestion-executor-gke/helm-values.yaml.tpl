global:
  datahub:
    gms:
      url: "${datahub_gms_url}"
      secretRef: "${datahub_secret_name}"
      secretKey: "token"
    executor:
      pool_id: "${executor_pool_id}"
      ingestions:
        max_workers: ${ingestion_max_workers}
        signal_poll_interval: ${ingestion_signal_poll_interval}
      monitors:
        max_workers: ${monitors_max_workers}

workloadKind: "Deployment"
replicaCount: ${replica_count}

image:
  repository: "${image_repository}"
  pullPolicy: "Always"
  tag: "${image_tag}"

imagePullSecrets:
  - name: "${registry_secret_name}"

resources:
  requests:
    memory: "${resources_requests_memory}"
    cpu: "${resources_requests_cpu}"
  limits:
    memory: "${resources_limits_memory}"
    cpu: "${resources_limits_cpu}"

serviceAccount:
  create: true
  name: "datahub-executor-sa"
%{ if enable_workload_identity ~}
  annotations:
    iam.gke.io/gcp-service-account: "${gcp_service_account_email}"
%{ else ~}
  annotations: {}
%{ endif ~}

podAnnotations:
%{ for key, value in pod_annotations ~}
  ${key}: "${value}"
%{ endfor ~}
  environment: "${environment}"

podSecurityContext:
  fsGroup: 1000

securityContext:
  runAsNonRoot: true
  runAsUser: 1000

livenessProbe:
  initialDelaySeconds: 30
  periodSeconds: 30
  failureThreshold: 3
  timeoutSeconds: 5

readinessProbe:
  initialDelaySeconds: 30
  periodSeconds: 30
  failureThreshold: 3
  timeoutSeconds: 5

%{ if length(node_selector) > 0 ~}
nodeSelector:
%{ for key, value in node_selector ~}
  ${key}: "${value}"
%{ endfor ~}
%{ else ~}
nodeSelector: {}
%{ endif ~}

%{ if length(tolerations) > 0 ~}
tolerations:
%{ for toleration in tolerations ~}
  - %{ if toleration.key != null }key: "${toleration.key}"%{ endif }
    %{ if toleration.operator != null }operator: "${toleration.operator}"%{ endif }
    %{ if toleration.value != null }value: "${toleration.value}"%{ endif }
    %{ if toleration.effect != null }effect: "${toleration.effect}"%{ endif }
%{ endfor ~}
%{ else ~}
tolerations: []
%{ endif ~}

extraEnvs:
%{ if enable_debug ~}
  - name: "DATAHUB_DEBUG"
    value: "true"
%{ endif ~}
%{ if enable_custom_transformers ~}
  - name: "PYTHONPATH"
    value: "/opt/datahub/transformers:$PYTHONPATH"
%{ endif ~}

%{ if enable_custom_transformers ~}
# Custom transformer volume (single configmap with all files)
extraVolumes:
  - name: custom-transformers
    configMap:
      name: "${custom_transformers_configmap}"
      defaultMode: 0755

extraVolumeMounts:
  - mountPath: /opt/datahub/transformers
    name: custom-transformers
%{ endif ~}
