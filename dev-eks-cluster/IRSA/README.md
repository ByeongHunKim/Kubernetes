# 1. prerequisite

## 1.1 OIDC 공급자가 세팅 되어 있어야 한다 ( dev cluster는 설정 되어있음 )

- [reference](https://docs.aws.amazon.com/ko_kr/emr/latest/EMR-on-EKS-DevelopmentGuide/setting-up-enable-IAM.html)

## 1.2 aws cli 에 credential 설정 ( 본인 계정 )

## 1.3 kubectl 설정 ( dev cluster 에 연결 )

### 1.4 aws secrets manager 생성

- 프로젝트 팀에서 요청 온 요구사항에 따라 생성해주면 됨

---

# 2. IRSA 세팅

- [reference](https://whchoi98.gitbook.io/k8s/eks-security/service_account)

## 2.1 asm-access-policy.json 준비
- BatchGetSecertValue 를 쓸 때는 policy가 좀 다르다


- 생성파일 예시

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:BatchGetSecretValue",
                "secretsmanager:ListSecrets"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": [
                "arn:aws:secretsmanager:ap-northeast-2:005515xxxxx:secret:nestjs-boilerplate-config-variable/development/*"
            ]
        }
    ]
}
```

- 생성 파일

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:BatchGetSecretValue"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:ListSecrets"
            ],
            "Resource": [
                "arn {프로젝트이름}/{환경}/*" 
            ]
        }
    ]
}
```

- `"arn {프로젝트이름}/{환경}/*"` 으로 해야 추후에 secret 값이 추가되어도 policy 를 수정하지 않아도 된다

### 2.1.1 IAM 정책생성 예제

```yaml
aws iam create-policy --policy-name prjName-dev-asm-read-iam-policy --policy-document file://asm-access-policy.json

{
    "Policy": {
        "PolicyName": "EKSSecretsManagerReadOnly",
        "PolicyId": "ANPAQCSGH......",
        "Arn": "arn:aws:iam::005515xxxxx:policy/EKSSecretsManagerReadOnly",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2024-03-08T05:42:14+00:00",
        "UpdateDate": "2024-03-08T05:42:14+00:00"
    }
}

```

### 2.1.2 IAM policy 생성

- policy naming convention
- 아래 명령어를 policy.json 파일이 있는 곳에서 실행

```yaml
aws iam create-policy --policy-name {이름} --policy-document file://{policy.json파일}
```

## 2.2 네임스페이스 생성

- `예제`
  - `k create namespace nestjs-boilerplate-config-variable`
- `k create namespace {프로젝트가 배포될 네임스페이스}`

## 2.3 해당 네임스페이스에 service account 생성 예제

```yaml
eksctl create iamserviceaccount \
    --name prjName-service-account \
    --namespace your-namespace \
    --cluster dev \
    --attach-policy-arn <Policy-arn> \
    --approve \
    --override-existing-serviceaccounts

2024-03-08 14:59:41 [ℹ]  2 existing iamserviceaccount(s) (kube-system/aws-load-balancer-controller,kube-system/efs-csi-controller-sa) will be excluded
2024-03-08 14:59:41 [ℹ]  1 iamserviceaccount (nestjs-boilerplate-config-variable/asm-reader-dev) was included (based on the include/exclude rules)
2024-03-08 14:59:41 [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
2024-03-08 14:59:41 [ℹ]  1 task: {
    2 sequential sub-tasks: {
        create IAM role for serviceaccount "nestjs-boilerplate-config-variable/asm-reader-dev",
        create serviceaccount "nestjs-boilerplate-config-variable/asm-reader-dev",
    } }2024-03-08 14:59:41 [ℹ]  building iamserviceaccount stack "eksctl-dev-addon-iamserviceaccount-nestjs-boilerplate-config-variable-asm-reader-dev"
2024-03-08 14:59:41 [ℹ]  deploying stack "eksctl-dev-addon-iamserviceaccount-nestjs-boilerplate-config-variable-asm-reader-dev"
2024-03-08 14:59:41 [ℹ]  waiting for CloudFormation stack "eksctl-dev-addon-iamserviceaccount-nestjs-boilerplate-config-variable-asm-reader-dev"
2024-03-08 15:00:11 [ℹ]  waiting for CloudFormation stack "eksctl-dev-addon-iamserviceaccount-nestjs-boilerplate-config-variable-asm-reader-dev"
2024-03-08 15:00:12 [ℹ]  created serviceaccount "nestjs-boilerplate-config-variable/asm-reader-dev"
```

## 2.4 해당 네임스페이스에 service account 생성

```yaml
eksctl create iamserviceaccount \
    --name {서비스 어카운트 이름} \
    --namespace  { 프로젝트가 배포 될 namespace 이름 } \
    --cluster { 클러스터 이름 } \
    --attach-policy-arn {2.1.1 IAM 정책생성한 policy arn} \
    --approve \
    --override-existing-serviceaccounts
```

- service account에서 사용할 role은 자동으로 policy가 연결되어서 생성된다.

### 2.3.1 service account 생성 확인

```yaml
k get serviceaccount -n nestjs-boilerplate-config-variable

NAME             SECRETS   AGE
asm-reader-dev   0         37s
default          0         6m48s
```

---

# 3. 프로젝트 설정

## 3.1 gitlab project variable 설정 ( nestjs 한정 )

- migrate을 수행하는 helm pre upgrade hook을 실행 시키기 위해서 프로젝트의 gitlab variable을 추가해야한다. 그래야 어플리케이션 파드가 뜨기 전에 migrate deploy를 진행하고 문제가 없으면 어플리케이션 파드가 뜬다

- 참고 
  - auto deploy image를 사용할 때 안에 있는 template 중 하나인 db-migrate-hook.yaml 을 사용하는데 프로젝트의 auto-deploy-values-dev.yaml 에서 위의 yaml을 실행 시키는 조건의 value를 넣어줘도 DB_MIGRATE 값이 한번 더 덮어씌워서 variable을 사용해야함


- 프로젝트 좌측에서 Settings → CI/CD → Variables 에 접속 하여 아래 값 추가
  - key
    - `DB_MIGRATE`
  - value
    - `npm run db:migrate`



## 3.2 gitlab project repo 설정

- feature branch 에서 아래 작업 진행
- `.gitlab/auto-deploy-values-dev.yaml`
  - 아래 name에 위에서 생성한 service account 이름 넣고 push하기
  - 참고
    - 위에서 언급한 db-migrate-hook이 Job을 생성해주고 해당 Job이 migrate pod를 생성해서 migrate deploy를 수행하는 것인데, 해당 yaml에 serviceAccount를 인자로 받는 부분이 없어서 default로 지정되어 해당 secret value에 접근할 수 없는 문제가 발생했다. auto-deploy-image를 커스텀해서 Nexus에 올린 이미지를 사용하는 것으로 변경했다

    ```yaml
    serviceAccount:
      create: false  # 기존 서비스 어카운트를 사용하는 경우 true 대신 false를 사용합니다.
      name:   # 사용하고자 하는 서비스 어카운트의 이름을 지정합니다. ( 서비스 어카운트 생성 : devops engineer 업무 - https://www.notion.so/memecore/dev-eks-IRSA-c325c11cfbdb41439ae5783ee8005136?pvs=4 )
    ```

- PR 날려서 development로 머지하기

# 트러블 슈팅 방법
- ./script.sh {service-account-name} {namespace}
  - 위 스크립트를 실행시키면 해당 네임스페이스에 연결된 service account가 가진 role, policy 정보를 확인해서 어떤 리소스에 접근이 부여됐는 지 aws console에 접근하지 않아도 확인할 수 있다
