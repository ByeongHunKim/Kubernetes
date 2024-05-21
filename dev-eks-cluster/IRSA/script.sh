#!/bin/bash

# 사용할 Kubernetes 서비스 계정 이름과 네임스페이스를 입력받습니다.
SERVICE_ACCOUNT_NAME=$1
NAMESPACE=$2

# 서비스 계정에서 IAM 역할 ARN을 추출합니다.
ROLE_ARN=$(kubectl get sa $SERVICE_ACCOUNT_NAME -n $NAMESPACE -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}')

echo "IAM 역할 ARN: $ROLE_ARN"

# IAM 역할에 연결된 정책 목록을 조회합니다.
POLICY_ARNS=$(aws iam list-attached-role-policies --role-name $(basename $ROLE_ARN) --query 'AttachedPolicies[*].PolicyArn' --output text)

echo "연결된 IAM 정책 목록:"
echo $POLICY_ARNS

# 각 정책의 세부 정보를 조회합니다.
for POLICY_ARN in $POLICY_ARNS
do
  echo "정책 ARN: $POLICY_ARN"
  POLICY_DETAILS=$(aws iam get-policy --policy-arn $POLICY_ARN)
  echo $POLICY_DETAILS
  DEFAULT_VERSION_ID=$(echo $POLICY_DETAILS | jq -r '.Policy.DefaultVersionId')
  POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn $POLICY_ARN --version-id $DEFAULT_VERSION_ID --query 'PolicyVersion.Document' --output json)

  echo "정책 버전: $DEFAULT_VERSION_ID"
  echo "정책 상세 내용:"
  echo $POLICY_DOCUMENT | jq .

  # 정책 문서에서 Actions와 Resources를 출력합니다.
  ACTIONS=$(echo $POLICY_DOCUMENT | jq -r '.Statement[].Action')
  RESOURCES=$(echo $POLICY_DOCUMENT | jq -r '.Statement[].Resource')

  echo "허용된 작업:"
  echo $ACTIONS
  echo "대상 리소스:"
  echo $RESOURCES
done