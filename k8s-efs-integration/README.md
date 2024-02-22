# 목차

1. [클러스터에서 AWS EFS 사용을 위한 필수 사전 준비 작업](#1-클러스터에서-aws-efs-사용을-위한-필수-사전-준비-작업)
   1. [AWS EFS CSI 드라이버 설치 및 관련 설정](#11-aws-efs-csi-드라이버-설치-및-관련-설정)
2. [EFS 통합 및 사용 준비](#2-efs-통합-및-사용-준비)
   1. [EFS 파일 시스템 구성](#21-efs-파일-시스템-구성)
   2. [Kubernetes 리소스 설정](#22-kubernetes-리소스-설정)
   3. [애플리케이션 통합 테스트](#23-애플리케이션-통합-테스트)
3. [트러블 슈팅](#트러블-슈팅)

---

# 쿠버네티스 클러스터에서 AWS EFS 통합 프로세스

## 1. 클러스터에서 AWS EFS 사용을 위한 필수 사전 준비 작업
### 1.1 AWS EFS CSI 드라이버 설치 및 관련 설정
- IAM 정책 생성: AWS EFS CSI 드라이버가 EFS를 관리하기 위해 필요한 권한을 가지는 IAM 정책을 생성합니다.
- IAM 서비스 어카운트 설정: 생성된 IAM 정책을 Kubernetes 서비스 어카운트에 연결하여, EFS CSI 드라이버가 AWS 리소스에 접근할 수 있도록 합니다. 
- CSI 드라이버 설치: Kubernetes 클러스터에 AWS EFS CSI 드라이버를 설치하여, EFS 볼륨을 Pod에 마운트할 수 있게 합니다.
## 2. EFS 통합 및 사용 준비
### 2.1 EFS 파일 시스템 구성
- AWS 관리 콘솔 또는 AWS CLI를 통해 EFS 파일 시스템을 생성하고, 적절한 설정(액세스 포인트, 보안 그룹 설정 등)을 진행합니다. 
### 2.2 Kubernetes 리소스 설정
- StorageClass 생성: EFS CSI 드라이버를 사용하기 위한 StorageClass를 정의하고, 필요한 파라미터(fileSystemId, accessPointId 등)를 포함시킵니다.
- PersistentVolumeClaim(PVC) 등록: 애플리케이션에서 사용할 PVC를 생성하여, StorageClass를 참조하도록 설정합니다.
### 2.3 애플리케이션 통합 테스트
- 테스트 애플리케이션 Pod를 배포하고, 정의된 PVC를 사용하여 EFS 볼륨을 마운트합니다. Pod 내부에서 파일 생성 및 수정을 통해 EFS 볼륨의 정상적인 작동을 검증합니다.

---

# 트러블 슈팅

## 🚨 문제

Kubernetes 클러스터에서 AWS Elastic File System(EFS)을 사용하여 퍼시스턴트 스토리지를 제공하려 할 때, 테스트 애플리케이션 Pod에서 EFS 볼륨을 마운트하는 과정에서 `MountVolume.SetUp failed`와 같은 에러가 발생, 볼륨 마운트 실패.

## 🧨 원인

### **예상원인1 -  Storage Class 설정 오류**: `storage-class.yaml`에서 필요한 EFS 파일 시스템 및 액세스 포인트 ID 파라미터 누락 또는 잘못 설정.

### **예상원인2 - Istio Sidecar 간섭**: Istio Sidecar 설정으로 인해 EFS로의 NFS 트래픽 차단

### **예상원인3 - 보안 그룹 인바운드 규칙 누락 : AWS 보안 그룹 설정에서 Kubernetes 노드에서 EFS로의 인바운드 NFS 트래픽(TCP 포트 2049) 허용 규칙 누락**

---

## 🔨 해결

**예상원인1 검증 - 기존 Storage Class 올라간 상태에서 파라미터를 수정할 수 없다고 해서 삭제 후** 필요한 EFS 파일 시스템 및 액세스 포인트 ID 파라미터를 모두 제대로 넣은 걸 확인 후 테스트 파드를 띄워봤지만 같은 에러 발생

---

**예상원인2 검증 -** efs-service-entry.yaml 을 넣고 다시 테스트 파드를 띄워봤지만 아래와 같은 에러 다시 발생

- efs-service-entry.yaml

    ```yaml
    apiVersion: networking.istio.io/v1beta1
    kind: ServiceEntry
    metadata:
      name: efs-service-entry
    spec:
      hosts:
      - <EFS-DNS-Name>
      ports:
      - number: 2049
        name: nfs
        protocol: TCP
      location: MESH_EXTERNAL
    ```


```yaml
Warning  FailedMount  58s    kubelet MountVolume.SetUp failed for volume "pvc-509ea87a-c28b-4383-a46a-8424ed3a96a0" : rpc error: code = DeadlineExceeded desc = context deadline exceeded
```

<aside>
💡 추후에 service entry 영향이 있는 지 없는 지 검증해보았으나 **`ServiceEntry`** 설정이 EFS와의 연결에 결정적인 역할을 하지 않았음

이 결과는 Istio의 외부 트래픽 정책이 **`ALLOW_ANY`**로 설정되어 있다는 것을 의미하는 건가

</aside>

```yaml
   ~/m/k/Kubernetes/k8s-efs-integration    main  kubectl get serviceentry --all-namespaces

NAMESPACE   NAME                HOSTS                                                       LOCATION        RESOLUTION   AGE
default     efs-service-entry   ["fs-.efs.ap-northeast-2.amazonaws.com"]   MESH_EXTERNAL                15h

   ~/m/k/Kubernetes/k8s-efs-integration    main  kubectl delete serviceentry efs-service-entry -n default

serviceentry.networking.istio.io "efs-service-entry" deleted

   ~/m/k/Kubernetes/k8s-efs-integration    main  k apply -f pod.yaml        ✔    system   11:35:38 
persistentvolumeclaim/efs-claim unchanged
pod/efs-app created

   ~/m/k/Kubernetes/k8s-efs-integration    main  k get pods                 ✔    system   11:37:42 
NAME      READY   STATUS    RESTARTS   AGE
efs-app   2/2     Running   0          112s
```

**OutBoundTrafficPolicy확인**

<aside>
💡 **`outboundTrafficPolicy`**에 대한 설정이 명시적으로 포함되어 있지 않아서 이는 Istio의 기본 외부 트래픽 정책  **`ALLOW_ANY`** 이 사용되고 있음으로 파악

</aside>

```yaml
   ~/m/k/Kubernetes/k8s-efs-integration    main  kubectl get configmap istio -n istio-system -o yaml

apiVersion: v1
data:
  mesh: |-
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      proxyMetadata: {}
      tracing:
        zipkin:
          address: zipkin.istio-system:9411
    defaultProviders:
      metrics:
      - prometheus
    enablePrometheusMerge: true
    rootNamespace: istio-system
    trustDomain: cluster.local
  meshNetworks: 'networks: {}'
kind: ConfigMap
metadata:
  annotations:
    meta.helm.sh/release-name: istiod
    meta.helm.sh/release-namespace: istio-system
  creationTimestamp: "2024-02-06T07:38:29Z"
  labels:
    app.kubernetes.io/managed-by: Helm
    install.operator.istio.io/owning-resource: installed-state
    install.operator.istio.io/owning-resource-namespace: istio-system
    istio.io/rev: default
    operator.istio.io/component: Pilot
    operator.istio.io/managed: Reconcile
    operator.istio.io/version: 1.20.2
    release: istio
  name: istio
  namespace: istio-system
  resourceVersion: "419071"
  uid: 927d591e-0c62-4a23-84e6-bf07f8a37f97
```

---

**예상원인3 검증 -**

**보안 그룹 NFS 트래픽 허용 확인  → 없음 → Kubernetes 노드가 위치한 보안 그룹에 대해 EFS로의 인바운드 NFS 트래픽(TCP 포트 2049)을 허용하는 규칙 추가**

---

## 🌠 결과 - Kubernetes 클러스터 노드가 EFS와 통신할 수 있는 네트워크 경로를 열어주어 해결

Kubernetes 클러스터 내에서 실행 중인 애플리케이션이 AWS EFS 볼륨을 스토리지로 사용하려면, 클러스터 노드가 EFS와 네트워크 통신을 성공적으로 수행할 수 있어야 합니다. 클러스터 노드와 EFS 모두 VPC 내에 위치해 있을 경우, 노드는 VPC 내 할당된 프라이빗 IP 주소를 사용

보안 그룹에 프라이빗 IP 주소 범위에 대해 2049 인바운드 규칙을 추가함으로써, VPC 내의 모든 리소스가 EFS 볼륨에 NFS 프로토콜을 사용하여 접근할 수 있도록 허용.

---

# eks dev cluster 에 EFS 볼륨 통합 테스트 

## [reference](https://ltlkodae.tistory.com/52)

## 1. RECLAIM_POLICY : DELETE 인 것

- test pod`(pod.yaml)`가 `RECLAIM_POLICY : DELETE 인 것` 인 pv를 가지고 있을 때 pod를 지우면 같이 삭제된다 `$k get pv` 했을 때 안 보임. 근데 aws console에는 해당 pv의 엑세스 포인트가 남아있다.

## 2. RECLAIM_POLICY : RETAIN 인 것

- test pod`(efs-retain-option/pod-efs-retain.yaml)` 가 `RECLAIM_POLICY : RETAIN 인 것` 인 pv를 가지고 있을 때 pod를 지우면 같이 삭제되지 않는다. 그리고 파드를 다시 띄워보면 처음이 파드를 생성하고 만들었던 text file이 다시 남아 있다.

```bash
# retain pvc와 연결 후 파드를 처음 띄웠을 때
kubectl exec -it efs-app -- /bin/sh
cd /data
echo "HELLO WORLD" > /data/test.txt


# 삭제 후 다시 파드를 띄우고 접속했을 때
kubectl exec -it efs-app -- /bin/sh

cd data/
ls
# out  test.txt
```



---

# 메모

- StorageClass가 어떤식으로 동작하는가 + 왜 필요한가?

- PersistentVolumeClaim ( PVC ) 생성이 어떤 식으로 동작하는가 ? 왜 필요한가?

- 동적 프로비저닝

- 정적 프로비저닝

- 파드 생성 및  EFS 볼륨 테스트

---