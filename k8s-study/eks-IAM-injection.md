# Intro

- EKS dev cluster를 세팅하면서 AWS 의 Loadbalancer를 이용하기 위해서는 aws loadbalacner controller를 설치해줘야했다
- 이 때 loadbalancer controller는 aws resource인 loadbalancer 를 새로 생성하고 지우기 위해서 권한이 필요하게 되는데 이 때 사용되는 것이 IRSA 개념
- 이렇듯 EKS 상에서 AWS Service 나 Resource 를 사용하게 될 때 접근권한을 얻을 때는 항상 위 문제에 직면하게 된다
- AWS Resource를 eks 에서 사용하려면 IAM 을 주입 받아야 하는데 무심코 사용했었던 IRSA 그리고 다른 best practices 들은 무엇이 있는 지 학습을 하기로 결심했다


## OIDC
- 클러스터의 OIDC 공급자는 공개적으로 엑세스할 수 있고 표준 OIDC endpoint를 노출한다
  - 누구나 공개 키 및 기타 필요한 정보를 쉽게 검색할 수 있다

```bash
$ OIDC_URL=$(
  aws eks describe-cluster --name your-eks-cluster \
  --query cluster.identity.oidc.issuer --output text
)
$ echo $OIDC_URL
https://oidc.eks.eu-west-1.amazonaws.com/id/AF26D840E519D2F3902468224667D259

$ curl $OIDC_URL/.well-known/openid-configuration
{
  "issuer": "https://oidc.eks.eu-west-1.amazonaws.com/id/AF26D840E519D2F3902468224667D259",
  "jwks_uri": "https://oidc.eks.eu-west-1.amazonaws.com/id/AF26D840E519D2F3902468224667D259/keys",
  "authorization_endpoint": "urn:kubernetes:programmatic_authorization",
  "response_types_supported": [
    "id_token"
  ],
  "subject_types_supported": [
    "public"
  ],
  "claims_supported": [
    "sub",
    "iss"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ]
}
```

- 외부 자격 증명 공급자와 마찬가지로 JWT 토큰을 자격 증명 공급자를 신뢰하는 모든 IAM 역할에 대한 임시 AWS 자격 증명으로 교환 할 수 있다


## IRSA on the EKS cluster (IAM Roles for Service Account)
- reference
  - [enable IAM Roles for Service Accounts on the EKS Cluster](https://docs.aws.amazon.com/emr/latest/EMR-on-EKS-DevelopmentGuide/setting-up-enable-IAM.html)
- 인스턴스 프로파일로 권한을 부여한다면, Pod 단위가 아닌 Node 단위로 권한 부여가 되므로 디테일한 권한부여를 할 수 없다
- Service Account에 annotation을 통해서 IAM의 Role을 부여하고 이를 통해서 해당 Service Account를 사용하는 Service는 해당 권한을 갖을 수 있게 되는 것
- Annotation을 통해서 role을 부여할 때 OIDC ( OpenID Connect) issuer URL 이 사용되게 된다. 따라서 EKS 에서 IRSA 라는 개념을 적용하여 사용하기 위한 도구로 OIDC identity provider를 만들어 줘야 함
- OIDC는 AccessToken과 ID Token이 발행되는데 이 ID Token이 신원정보를 갖고 있는 토큰이 된다

## EKS Pod Idenetity
- reference
  - [EKS Pod Identity](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/pod-identities.html)
  - [서비스 계정에 대한 IAM 역할](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/iam-roles-for-service-accounts.html)
- AWS 자격 증명을 생성하여 컨테이너에 배포하거나 Amazon EC2 인스턴스의 역할을 사용하는 대신 IAM 역할을 kubernetes service account 와 연결하고 pod에서 해당 service account를 사용하도록 구성
- EKS Pod Identity는 OIDC 자격 증명 공급자를 사용하지 않는다

## EKS 포드 ID 개요 및 IRSA와의 차이점
- 구현은 IRSA와 유사하다
- 클러스터 내 변경이 필요하지 않으므로 사용하기가 더 쉽다
  - 대신 다음을 사용하여 특정 Kubernetes 계정에서 실행되는 IAM 역할 포드가 액세스해야 하는 IAM 역할을 관리할 수 있다 eks:CreatePodIdentityAssociation
  ```bash 
  aws eks create-pod-identity-association \
    --cluster-name your-cluster \
    --namespace your-namespace \
    --service-account your-pod-service-account \
    --role-arn arn:aws:iam::012345678901:role/PodRole
  ```
- 이 서비스 계정을 사용하여 새 파드를 생성하면 EKS 승인 컨트롤러가 두 가지 환경 변수 AWS_CONTAINER_CREDENTIALS_FULL_URI와 AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE 를 사용한다.
- 이로 인해 AWS SDK 및 CLI는 내부 API를 호출하여 IRSA와 동일한 Kubernetes 서비스 계정 토큰을 전달하게 됩니다. sts:AssumeRoleWithWebIdentity그러면 이 내부 API가 사용자를 대신해 호출을 수행한다

---

## Amazon EKS Pod Identity Agent 설정
- reference
  - [aws docs](https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/pod-id-agent-setup.html)