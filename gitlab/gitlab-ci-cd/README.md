# Intro

- 이번에 데브옵스 업무를 진행하며 gitlab이 좋다고 느낀점
    - gitlab에서는 [ci/cd](https://jminie.tistory.com/127) 기능을 자체적으로 지원하기에 Jenkins 같은 별도의 툴이 필요 없다.
    - 일부 CI/CD 플랫폼의 경우, Kubernetes 또는 컨테이너 레지스트리(container registry)에 연결하기 위한 추가 플러그인이 여전히 필요하다
    - 여기에 이러한 개별 도구를 관리하기 위한 유지관리, 플러그인 및 업그레이드 요구사항을 추가하면 어려워서 생산성이 더 낮아지는 것 같다
---
- gitlab ci/cd 장단점
    - 사용하기 쉬움
        - 모든 개발자가 이해할 수 있는 YAML 구성을 사용하므로 파이프라인을 더 빠르게 빌드할 수 있다
    - 클라우드 네이티브 ci/cd
        - 내장된 컨테이너 레지스트리와 Kubernetes 통합을 통해, 클라우드 네이티브 개발을 지원한다
    - Runner를 사용하면, 개발자는 더 이상 빌드를 기다릴 필요가 없으며 Commit / Merge/ Release 등의 이벤트가 발생하는 것을 감지하고 이로부터 CI/CD 파이프라인이 동작할 수 있는 환경을 제공한다
    - 하지만 gitlab ci 설정 관련해서 설정값을 알아봐야해서 커스터마이징 할 때 난이도가 좀 높을 것 같다
---
# GitLab CI/CD를 사용하기 위한 사전 조건 1. **Gitlab-Runner**

- **프로젝트에서 Job을 실행할 수 있는 하나 이상의 Runner가 인스턴스, 프로젝트 또는 그룹에 대하여 등록되어 있어야 함**

- Runner는 온프레미스 서버, 가상머신, 또는 클라우드 인스턴스 등 어디에나 설치될 수 있다
    - 현재는 playground 클러스터에 설치되어있다
        - pipeline이 하나 동작할 때 pod가 하나 뜨고 내리고를 반복하는데 이렇게 리소스를 사용하다보니 playground에 설치되어있다
        - GitLab Runner는 배포와 관련된 작업을 Kubernetes Agent에 위임하고, 배포는 Kubernetes 클러스터에서 직접 처리된다
        - 그래서 Kubernetes 클러스터에 GitLab Runner를 별도로 설치하지 않고도 EKS 클러스터 내에서 애플리케이션을 배포할 수 있다
- Gitlab Build -> Runners 메뉴 에서 확인 가능
---
- Gitlab Runner 란?
    - CI/CD Job을 실행하는 에이전트
    - GitLab 서버에서 파이프라인 작업을 할당받아 실행하고 결과를 GitLab 서버로 다시 보낸다
    - 이벤트가 발생 시, 레포지토리 루트경로에 등록 되어 있는 `.gitlab-ci.yml`  파이프라인 설정을 참고하여 CI/CD를 동작시키게 된다
        - 결과적으로 `.gitlab-ci.yml`파일을 올려두면 해당 파일을 인식해 gitlab-runner를 이용, pipeline이 실행되는 구조이다
---
- gitlab runner의 작동방식
1. 완료된 Gitlab 레포지토리에 코드 변경 사항을 push 하면 Gitlab은 하나 이상의 작업이 포함된 새 파이프라인을 생성한다
2. GitLab Runner는 Gitlab 서버에서 실행할 새 작업을 주기적으로 확인한다.
    1. 작업을 사용할 수 있는 경우 작업을 선택하고 실행을 시작한다
    2. `1번` 에서 언급한대로 `.gitlab-ci.yml` 파일에 정의된 작업 단계 ( 빌드, 테스트, 배포 등 ) 을 실행한다
3. Runner가 작업을 실행하면 실시간 상태 업데이트, 로그 등을 Gitlab 서버로 다시 보낸다
    1. 이를 통해 파이프라인 결과 확인이 가능하다
4. 작업이 완료되면 Runner 는 최종 상태를 GitLab 서버에 보고한다
---
# GitLab CI/CD를 사용하기 위한 사전 조건 2. Kubernetes Agent

- **프로젝트를 배포할 하나 이상의 Kubernetes Agent가 등록되어 있어야 함**
- GitLab과 Kubernetes 클러스터 간의 연결을 관리해주는 에이전트
- gitlab 메뉴에서 Operate 의 Kubernetes clusters 섹션에서 확인 ( 현재는 eks-dev, playground cluster agents들이 등록 되어있다 )
- agent가 추가되면 , GitLab은 Kubernetes 클러스터 내의 리소스를 관리하고, 해당 클러스터 내에서 직접 작업을 실행할 수 있게 된다
    - Kubernetes Agent를 사용하면, GitLab CI/CD 파이프라인이 Kubernetes 클러스터 내에서 애플리케이션을 배포할 수 있다
    - 아래 사진을 보면 직접 로컬에서 kubernetes context를 바꿀 수 있고 바꾼 후에 해당 클러스터에 명령을 내릴 수 있다. 배포 작업을 수동으로 하지 않게 해준다고 생각하면 된다
    - `KUBE_CONTEXT` 변수를 `gitlab-ci.yml` 파일에 설정함으로써 GitLab은 해당 Kubernetes 클러스터와 통신하여 Kubernetes Agent를 통해 배포 작업을 수행할 수 있다
    - 실제 배포는 runner가 Kubernetes Agent에게 배포하라고 명령을 하며 진행됨. 이 때 각 레포지토리와 연결된 Kubernetes 클러스터 내에서 이루어진다.
---
- 프로젝트 `.gitlab/auto-deploy.values.dev.yaml` 에 존재해야하는 파일은 Kubernetes 환경에서 애플리케이션을 배포할 때 사용되는 Helm 차트의 값을 정의하는 역할을 한다
    - 현재의 구성
    1. 서비스 포트 설정
    2. Ingress 설정 및 관련 어노테이션
        1. `ingress.class` :  Ingress는 kubernetes 의 내장 리소스로 외부 트래픽을 Cluster 내부 service 로 라우팅 시켜준다. 트래픽을 수신하는 컴포넌트는 Pod 형태로 실행되는 Ingress controller인데 아래 2개는 ingress controller 의 종류이다.
            1. istio
                1. k8s 클러스터 내부의 서비스 간 통신을 관리. Istio에서는 `istio-ingressgateway`를 사용하여 클러스터 외부에서 유입되는 트래픽을 관리하고 적절한 서비스로 라우팅 해준다
                2. nginx 보다 더 많은 기능을 제공하지만, 설정과 관리가 더 복잡하다
            2. nginx
                1. 설정이 비교적 간단하고, Ingress 리소스를 사용하는 k8s 환경에서 트래픽 라우팅 규칙을 쉽게 정의할 수 있다
        2. `tls-acme`
            1. `"true"`는 해당 Ingress에 대해 자동 TLS 인증서 발급과 관리를 활성화하겠다는 의미.`"false"`로 설정된 경우는 이 기능을 사용하지 않겠다는 것을 의미
            2. 현재는 acm 에서 발급받은 인증서를 사용하기 때문에 false 로 설정
    3. livenessProbe 및 readinessProbe 설정을 포함한 컨테이너 생명주기 관리
        1. livenessProbe
            1. **목적**: 컨테이너가 아직 살아있는지(즉, 작동 중인지) 확인. 이 프로브가 실패하면, Kubernetes는 컨테이너를 재시작. 이는 애플리케이션이 더 이상 정상적으로 작동하지 않는 경우에 대응하기 위한 것
            2. **적용**: 컨테이너가 정상적으로 작동하고 있다는 것을 간단하게 확인할 수 있는 로직이 좋다.
        2. readinessProbe
            1. **목적**: 컨테이너가 요청을 수락할 준비가 되었는지 확인. 이 프로브가 실패하면, Kubernetes는 해당 포드로 트래픽을 보내지 않는다. 이는 애플리케이션이 초기화 중이거나, 의존하는 외부 서비스와의 연결을 기다리는 등 준비가 완료되지 않은 경우에 대응하기 위한 것
            2. **적용**: 애플리케이션이 실제로 클라이언트 요청을 처리할 준비가 되었는지를 확인할 수 있는 보다 구체적인 로직이 필요할 수 있다. 예를 들어, 데이터베이스 연결 준비 상태나 필요한 외부 서비스와의 연결 상태 등을 확인할 수 있다
- 이 두 프로브를 통해 Kubernetes는 컨테이너의 상태를 효과적으로 관리하며, 시스템의 안정성과 가용성을 향상시킨다
- 현재 백엔드는 임시로 health check endpoint를 직접 만들어 둔 곳으로 모두 설정해두었는데
- 올바르게 구성된 `livenessProbe`와 `readinessProbe`는 클라우드 네이티브 환경에서 애플리케이션을 운영할 때 매우 중요한 부분이다.
- `readinessProbe`는 실제로 트래픽을 처리할 준비가 되었는지를 포함하여 더 많은 조건을 검사해야 할 수 있기 때문
- 결론적으로, 두 프로브가 같은 엔드포인트를 바라보는 것이 꼭 문제는 아니지만, 각 프로브의 목적에 맞게 조정하는 것이 바람직하다
---
# GitLab CI/CD를 사용하기 위한 사전 조건 3. CI/CD job을 정의

- **GitLab CI에 대한 특정 지침을 구성하는 YAML 파일인 .gitlab-ci.yml의 구성**
    - 브랜치에 push 및 merge 같은 이벤트가 발생했을때 러너에게 시킬 작업을 설정해야 함.
    - `.gitlab-ci.yml` 파일을 리포지토리의 루트에 생성합니다. 이 파일에 CI/CD Job을 정의함.
    - 파일을 리포지토리에 커밋하면 러너가 Job을 실행. Job 결과는 파이프라인에 표시된다.
    - GitLab의 Auto DevOps 기능을 활용하기 위한 설정을 포함

<aside>
💡 현재 각 브랜치마다 다른 Kubernetes 컨텍스트를 사용하고, 헬름 차트 값을 다르게 적용하며, 개발, 스테이징, 프로덕션 환경에 맞는 설정을 할 수 있도록 되어있다. 이러한 설정을 통해 코드의 머지 요청이나 푸시가 있을 때마다 환경별 설정에 따라 자동으로 CI/CD 파이프라인이 실행되어, 코드를 빌드하고, 테스트하며, 배포할 수 있다.

</aside>
---
- Auto Devops
  - GitLab CI/CD 파이프라인의 한 부분으로, GitLab Runner에 의해 실행되는 작업들을 자동화
  - 만약 auto devops를 사용하지 않으면 아래에 있는 shell script를 직접 짜야한다
  - `include` 키워드를 사용하여 외부 yaml 파일을 포함할 수 있다. CI/CD 구성을 여러 파일로 나누어 긴 구성 파일의 가독성을 높이고, 전역 기본 변수와 같은 중복 구성을 방지할 수 있다.
      - 이 방식으로 `Bs-Auto-DevOps.gitlab-ci.yml` 파일을 포함시키면, 해당 파일에 정의된 모든 단계, 작업 및 구성이 현재 `.gitlab-ci.yml` 파일의 파이프라인에 동적으로 통합된다.
      - 파일 내에서 해당 `stage`들이 정의되어 있고 해당 `stage`들에 대응하는 `job`이 실행된다. 이는 파이프라인을 모듈화하고 재사용 가능하게 만들어, 보다 깔끔하고 관리하기 쉬운 CI/CD 구성을 가능하게 한다
- **Gitlab variables**
    - Gitlab 에는 이미 정의된 변수들이 있는데, yml 파일을 작성하기 전에 비밀로 관리해야하는 프로퍼티들을 깃랩에 저장한다.
---
GitLab에서 정의한 작업을 받아서 실행하고 그 결과를 GitLab 서버로 다시 보낸다.
GitLab Runner는 그 "무엇을" 실제로 "어떻게" 실행할 것인지를 처리한다.

Auto DevOps는 GitLab CI/CD 파이프라인의 한 부분으로, GitLab Runner에 의해 실행되는 작업들을 자동화.
Auto DevOps는 "무엇을" 할 것인지 정의

Kubernetes Agent는 GitLab과 Kubernetes 클러스터 간의 통신을 가능하게 하여, GitLab에서 Kubernetes 클러스터를 직접 관리하고 작업을 실행할 수 있게 해주는 역할을 한다.

이 모든 것들이 함께 작동하여 소스 코드의 빌드, 테스트, 배포 등의 과정을 자동으로 진행할 수 있게 한다.
---
# **파이프라인 결과 확인**

- 프로젝트의 **Build > Pipelines** 페이지에서 현재 및 이전 파이프라인 실행을 찾을 수 있으며, Merge Request의 **Pipelines** 탭으로 이동하여 파이프라인에 액세스할 수도 있다
- 사이드바에서 **CI/CD > Pipelines**를 클릭하면 CI 파이프라인이 실행되는 것을 확인할 수 있다.
- 아니면 gitlab과 slack을 연동해서 배포결과 알림을 받거나, 배포알림 뿐만 아니라 PR, comment, push 등 다른 이벤트에 대한 알림도 받는 방법이 있다