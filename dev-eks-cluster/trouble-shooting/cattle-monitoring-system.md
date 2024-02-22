# 🚨문제 : EFS 를 dev eks cluster에 통합 후 cattle-monitoring-system 에 storage-class 변경 후 기존 도메인으로 접속 불가

# 🧨원인

- `rancher-grafana.<your-project>.org` 에서 `rancher-grafana.dev.<your-project>.org` 로 설정되어있지 않아서였다.
  - DNS 설정에서 *.dev.<your-project>.org를 dev.<your-project>.org로 CNAME 설정하고 있었고, 
  - dev.<your-project>.org의 A 레코드에는 ALB가 지정되어 있었다면, rancher-grafana.dev.<your-project>.org 도메인은 ALB를 통해 트래픽을 받을 수 있어야 한다.
  - 그러나 실제 Grafana의 Ingress 설정에서는 rancher-grafana.<your-project>.org를 사용하고자 했다면, 이는 DNS 설정과 일치하지 않아 문제의 원인이 된다.

# 🔨해결

- values.yaml 의 hosts 설정을 제대로해서 다시 apply 진행하였다

# 🌠결과

- 접속이 잘 되었다

## before values.yaml

```yaml
alertmanager:
  config:
    global:
      resolve_timeout: 5m
grafana:
  adminPassword: <your-admin-password>
  enabled: true
  ingress:
    enabled: true
    hosts:
    - rancher-grafana.<your-project>.org
prometheus:
  prometheusSpec:
    retention: 10d
    scrapeInterval: 15s
```

## after values.yaml

```yaml
alertmanager:
  alertmanagerSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes:
          - ReadWriteMany
          resources:
            requests:
              storage: 2Gi
          storageClassName: efs-retain
  config:
    global:
      resolve_timeout: 5m
grafana:
  adminPassword: <your-admin-password>
  enabled: true
  ingress:
    enabled: true
    hosts:
    - rancher-grafana.<your-project>.org
prometheus:
  prometheusSpec:
    retention: 10d
    scrapeInterval: 15s
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes:
          - ReadWriteMany
          resources:
            requests:
              storage: 10Gi
          storageClassName: efs-retain
```

## after values.yaml 등록

```bash
helm upgrade rancher-monitoring rancher-monitoring/rancher-monitoring -f ~/<your-project-path>/rancher-monitoring-values.yaml  --namespace cattle-monitoring-system

Release "rancher-monitoring" has been upgraded. Happy Helming!
NAME: rancher-monitoring
LAST DEPLOYED: Thu Feb 22 15:08:25 2024
NAMESPACE: cattle-monitoring-system
STATUS: deployed
REVISION: 3
TEST SUITE: None
NOTES:
rancher-monitoring has been installed. Check its status by running:
  kubectl --namespace cattle-monitoring-system get pods -l "release=rancher-monitoring"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
````

## pvc, pv 정보

```bash
k get pvc
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
efs-retain-claim   Bound    pvc-<your-pvc-volume>   5Gi        RWX            efs-retain     3h6m

k get pv 
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                                                                                             STORAGECLASS   REASON   AGE
pvc-<your-pvc-volume>   5Gi        RWX            Retain           Bound    default/efs-retain-claim                                                                                          efs-retain              3h6m
pvc-<your-pvc-volume>   10Gi       RWX            Retain           Bound    cattle-monitoring-system/prometheus-rancher-monitoring-prometheus-db-prometheus-rancher-monitoring-prometheus-0   efs-retain              19m
```