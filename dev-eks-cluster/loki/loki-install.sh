k create namespace loki

helm install loki grafana/loki-stack \
  --namespace loki \
  --create-namespace \
  --set grafana.enabled=true \
  --set prometheus.enabled=false \
  --set loki.persistence.enabled=false \
  --set grafana.persistence.enabled=false


helm get values loki -n loki -o yaml

k get all -n loki

# istio 설정이 이미 되어있어서 gateway, virtualservice 설정

nano loki-gateway.yaml

nano loki-virtualservice.yaml

nano loki-istio-ingress.yaml

k apply -f loki-gateway.yaml
k apply -f loki-virtualservice.yaml
k apply -f loki-istio-ingress.yaml

k get ingress -n loki

# k get ingress -n loki 로 이름 넣어주기
k get ingress <k get ingress -n loki 로 이름 넣어주기> -n loki -o yaml


# 아래는 참고 할만 한 명령어들
k logs -l app=istio-ingressgateway -n istio-system
k describe gateway loki-gateway -n loki
k describe virtualservice loki-grafana-virtual-service -n loki

k delete gateway loki-gateway -n loki
k delete virtualservice loki-grafana-virtual-service -n loki

curl -Iv <도메인>