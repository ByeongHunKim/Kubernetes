helm get values loki -n loki -o yaml

#grafana:
#  enabled: true
#  persistence:
#    enabled: false
#loki:
#  persistence:
#    enabled: false
#prometheus:
#  enabled: false

helm upgrade loki grafana/loki-stack \
  --namespace loki \
  --set grafana.enabled=true \
  --set prometheus.enabled=false \
  --set loki.persistence.enabled=true \
  --set loki.persistence.existingClaim= \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.existingClaim=

#Release "loki" has been upgraded. Happy Helming!
#NAME: loki
#LAST DEPLOYED: Mon Feb 26 10:10:11 2024
#NAMESPACE: loki
#STATUS: deployed
#REVISION: 2
#NOTES:
#The Loki stack has been deployed to your cluster. Loki can now be added as a datasource in Grafana.
#
#See http://docs.grafana.org/features/datasources/loki/ for more detail.


helm get values loki -n loki -o yaml

#grafana:
#  enabled: true
#  persistence:
#    enabled: true
#    existingClaim:
#loki:
#  persistence:
#    enabled: true
#    existingClaim:
#prometheus:
#  enabled: false


k get pv
k get pvc