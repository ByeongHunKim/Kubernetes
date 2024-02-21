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

1. **Storage Class 설정 오류**: `storage-class.yaml`에서 필요한 EFS 파일 시스템 및 액세스 포인트 ID 파라미터 누락 또는 잘못 설정.
2. **Istio Sidecar 간섭**: Istio Sidecar 설정으로 인해 EFS로의 NFS 트래픽 차단.
3. **보안 그룹 인바운드 규칙 누락**: AWS 보안 그룹 설정에서 Kubernetes 노드에서 EFS로의 인바운드 NFS 트래픽(TCP 포트 2049) 허용 규칙 누락.

## 🔨 해결

1. **Storage Class 파라미터 수정**:
    - `storage-class.yaml`에 올바른 `fileSystemId`, `accessPointId`, `directoryPerms`, `provisioningMode` 추가.
2. **Istio ServiceEntry 설정 추가**:
    - `efs-service-entry.yaml` 추가하여 Istio가 EFS로의 트래픽 허용하도록 구성.
3. **AWS 보안 그룹 인바운드 규칙 추가**:
    - AWS 관리 콘솔 또는 AWS CLI를 사용하여, Kubernetes 노드가 위치한 보안 그룹에 대해 EFS로의 인바운드 NFS 트래픽(TCP 포트 2049)을 허용하는 규칙 추가.
    - 예시 명령어:

        ```bash
        aws ec2 describe-security-groups --group-ids <your-sg> # 보안 그룹의 규칙 확인
        aws ec2 describe-subnets --filters "Name=vpc-id,Values=<your-vpc-id>" # 쿠버네티스 클러스터가 배포된 VPC의 서브넷 설정을 확인
        aws ec2 authorize-security-group-ingress --group-id sg-xxxxxxx --protocol tcp --port 2049 --cidr <your-kubernetes-nodes-cidr>
        ```

    - 여기서 `<your-kubernetes-nodes-cidr>`는 쿠버네티스 노드의 CIDR 블록을 의미.

## 🌠 결과

- 해결1번  내용 -> 2번 -> 3번의 수정 사항 적용 후, Kubernetes 클러스터 내의 Pod에서 AWS EFS 볼륨 성공적으로 마운트 가능.
- 1~3번 모두 필수적으로 적용되어야 해결이 되는 것인지는 정확하게 파악을 못하였음
- 테스트 애플리케이션을 통해 EFS 볼륨에 파일 생성 및 AWS 관리 콘솔에서 EFS 볼륨 사용량 증가 확인으로, EFS와의 통신 및 데이터 저장 정상적으로 이루어짐을 검증.

이 과정을 통해 초기 설정 문제를 해결하고, Kubernetes 클러스터에서 AWS EFS를 안정적으로 사용할 수 있는 환경을 구축할 수 있었습니다.

---

# 메모

- StorageClass가 어떤식으로 동작하는가 + 왜 필요한가?

- PersistentVolumeClaim ( PVC ) 생성이 어떤 식으로 동작하는가 ? 왜 필요한가?

- 동적 프로비저닝

- 정적 프로비저닝

- 파드 생성 및  EFS 볼륨 테스트

---