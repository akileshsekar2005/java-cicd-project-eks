#!/usr/bin/env bash
# One-time AWS setup for the EKS pipeline. Run from the repo root with AWS CLI + eksctl installed
# and credentials configured (aws configure). Safe to re-run; existing resources are skipped.
set -euo pipefail

REGION="ap-south-1"
CLUSTER="java-cicd-cluster"
REPO="java-cicd-app"
ROLE="github-actions-eks-deploy"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

echo "==> Account: $ACCOUNT_ID  Region: $REGION"

echo "==> ECR repository"
aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" >/dev/null 2>&1 || \
  aws ecr create-repository --repository-name "$REPO" --region "$REGION" \
    --image-scanning-configuration scanOnPush=true >/dev/null

echo "==> EKS cluster (takes ~15-20 min)"
if ! eksctl get cluster --name "$CLUSTER" --region "$REGION" >/dev/null 2>&1; then
  eksctl create cluster -f eks/cluster.yaml
fi

echo "==> GitHub OIDC provider"
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1 || \
  aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 >/dev/null

echo "==> IAM role for GitHub Actions"
TMP="$(mktemp -d)"
sed "s/ACCOUNT_ID/${ACCOUNT_ID}/g" eks/github-oidc-trust-policy.json > "$TMP/trust.json"
sed "s/ACCOUNT_ID/${ACCOUNT_ID}/g" eks/github-actions-policy.json   > "$TMP/policy.json"
aws iam get-role --role-name "$ROLE" >/dev/null 2>&1 || \
  aws iam create-role --role-name "$ROLE" --assume-role-policy-document "file://$TMP/trust.json" >/dev/null
aws iam put-role-policy --role-name "$ROLE" --policy-name deploy --policy-document "file://$TMP/policy.json"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE}"

echo "==> Grant the role access to the cluster (EKS access entry)"
aws eks create-access-entry --cluster-name "$CLUSTER" --region "$REGION" \
  --principal-arn "$ROLE_ARN" >/dev/null 2>&1 || true
aws eks associate-access-policy --cluster-name "$CLUSTER" --region "$REGION" \
  --principal-arn "$ROLE_ARN" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster >/dev/null

echo
echo "Done. Add this GitHub repo secret:"
echo "  AWS_ROLE_ARN = $ROLE_ARN"
