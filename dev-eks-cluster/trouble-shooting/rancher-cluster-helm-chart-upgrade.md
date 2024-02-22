## 🚨 문제

- helm chart upgrade 하는 과정 중 Error: non-absolute URLs should be in form of repo_name/path_to_chart, got: rancher-stable 에러 발생

---

## 🧨 원인

- helm repo list로 확인 후에 경로를 다시 지정해줘야했다

---

## 🔨 해결

```bash
helm get values rancher -n cattle-system # before value 확인

helm get values rancher -n cattle-system > values.yaml # before value 다운로드

nano values.yaml # 수정

helm upgrade rancher rancher-latest/rancher -n cattle-system -f ~/memeCore/dev-cluster-setting-history/dev-cluster-rancher/values.yaml
# Error: non-absolute URLs should be in form of repo_name/path_to_chart, got: rancher-stable 에러 발생

helm repo list # 현재 helm repo list 체크 -> rancher-stable 확인 

NAME              	URL
grafana           	https://grafana.github.io/helm-charts
rancher-stable    	https://releases.rancher.com/server-charts/stable
jetstack          	https://charts.jetstack.io
gitlab            	https://charts.gitlab.io
istio             	https://istio-release.storage.googleapis.com/charts
eks               	https://aws.github.io/eks-charts
rancher-monitoring	https://charts.rancher.io
aws-efs-csi-driver	https://kubernetes-sigs.github.io/aws-efs-csi-driver/

helm upgrade rancher rancher-stable/rancher -n cattle-system -f ~/<path_to_chart>/values.yaml
# rancher-stable/rancher 로 경로 지정

W0222 18:14:15.359054    4067 warnings.go:70] cert-manager.io/v1beta1 Issuer is deprecated in v1.4+, unavailable in v1.6+; use cert-manager.io/v1 Issuer
Release "rancher" has been upgraded. Happy Helming!
NAME: rancher
LAST DEPLOYED: Thu Feb 22 18:14:12 2024
NAMESPACE: cattle-system
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

---

## 🌠 결과
- `helm get values rancher -n cattle-system` 명령어로 hosts 변경된 것 확인 + 접속 이상 없음 확인