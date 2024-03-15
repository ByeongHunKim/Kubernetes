# installation guide

```bash
k create namespace loki

k apply -f grafana-pvc.yaml
k apply -f loki-pvc.yaml

helm install loki grafana/loki-stack \
  --namespace loki \
  -f values.yaml
  
k apply -f loki-istio-ingress.yaml
```

# check loki resources after installation

```bash
k get all -n loki

k get ingress -n loki

k get pvc -n loki

k get pv
# NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   REASON   AGE
# pvc-380afeb3-xxxx-xxxx-xxxx-xxxxxxxxxxxx   10Gi       RWX            Retain           Bound    loki/loki-pvc      efs-retain              42m
# pvc-48f41199-xxxx-xxxx-xxxx-xxxxxxxxxxxx   5Gi        RWX            Retain           Bound    loki/grafana-pvc   efs-retain              43m 

k get secret loki-grafana -n loki -o jsonpath="{.data.admin-admin}" | base64 --decode
k get secret loki-grafana -n loki -o jsonpath="{.data.admin-password}" | base64 --decode
```

# helm commands

```bash
helm list -n loki
# NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
# loki    loki            1               2024-03-15 14:48:07.13774 +0900 KST     deployed        loki-stack-2.10.1       v2.9.3   

helm rollback loki <REVISION> -n loki 
```