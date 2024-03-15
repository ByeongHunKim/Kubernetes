# 1. loki password change
- `k edit secret loki-grafana -n loki` 명령어로 해도 수정되지 않는다
  - 초기 비밀번호로 접속해서 UI에서 바꿔야하는 것 같다.
  - secret 값을 계속 참조하지 않는다(?)

# 2. pv 설정 관련 
- PV(Persistent Volume)의 Reclaim Policy가 Retain으로 설정되어 있다면, 해당 PV를 사용하던 PVC(Persistent Volume Claim)가 삭제되거나 네임스페이스가 삭제되어도 PV는 여전히 존재 
- 이 상태에서 새로운 PVC를 생성하면, 기존에 있던 PV를 재활용하지 않고 새로운 PV가 프로비저닝된다
- Retain 정책은 데이터를 보존하려는 목적으로 사용되며, 데이터의 수동 관리를 필요로 한다. 즉, 기존 PV를 다시 사용하고 싶다면, 해당 PV를 수동으로 관리하여 새로운 PVC와 연결해야 한다

- 이 과정은 일반적으로 다음과 같은 단계를 포함한다:
  - 기존 PV의 상태를 확인하고, 여전히 존재하는지 확인한다
  - PV를 새 PVC에 할당하기 위해 PV의 claimRef 속성을 수정하거나 제거하여, 새로운 PVC가 PV를 차지할 수 있도록 한다
  - 새 PVC를 생성할 때, 기존 PV와 동일한 스펙(예: 스토리지 클래스, 사이즈 등)을 명시하여 PV와의 연결 가능성을 높인다

- 기존에 Retain 정책으로 설정된 PV를 다시 사용하려면, 먼저 해당 PV들의 현재 상태와 설정을 검토해야 한다
- PV가 여전히 존재하고 사용 가능한 상태인지, 그리고 PVC 요구 사항(예: storage class, access modes, storage size)과 일치하는지 확인
- 기존 PV를 재사용하기 위해 pvc.yaml 파일을 수정하는 대신, 기존 PV의 claimRef 섹션을 조정하여 해당 PVC와 연결하거나, 특정 PV를 직접 참조하는 방법이 있다
- 하지만, Kubernetes에서는 PVC가 특정 PV를 직접 선택하는 매커니즘을 제공하지 않는다
- 대신, PVC와 PV 간의 바인딩은 주로 스토리지 클래스, 액세스 모드, 요청된 스토리지 크기를 기반으로 자동으로 이루어진다

- 기존 PV를 재사용하려면 다음 단계를 따라야 한다:
  - 기존 PV의 상태 확인: kubectl get pv 명령어를 사용해 기존 PV의 상태를 확인. Released 상태의 PV를 찾아서 해당 PV가 재사용될 수 있도록 준비
  - PV의 claimRef 조정: 기존 PV가 특정 PVC에 바인딩되지 않도록 claimRef 항목을 삭제하거나 수정. 이렇게 하면 PV가 새로운 PVC 요청에 의해 자동으로 바인딩될 준비가 된다

  - 예를 들어, 특정 PV의 claimRef를 삭제하는 명령은 다음과 같을 수 있다:
    - `kubectl patch pv <your-pv-name> -p '{"spec":{"claimRef": null}}'`
  - PVC 생성: 수정할 필요 없이 기존의 grafana-pvc.yaml 및 loki-pvc.yaml 파일을 사용하여 PVC를 생성
  - 이때, storageClassName와 기타 스펙이 기존 PV와 일치해야 한다 이미 efs-retain이라는 스토리지 클래스를 사용하고 있으므로, 해당 스토리지 클래스를 사용하는 PV가 자동으로 선택됨

- 위의 절차는 기존 PV를 직접 재사용하는 가장 일반적인 방법
- 기존 PV가 PVC 요구 사항과 일치한다면, 자동으로 바인딩될 가능성이 높다
- 그러나 이러한 과정은 Kubernetes 클러스터와 스토리지 인프라의 구체적인 설정에 따라 달라질 수 있으므로, 실제 작업을 수행하기 전에 해당 환경의 문서화된 가이드라인을 참고하는 것이 좋다