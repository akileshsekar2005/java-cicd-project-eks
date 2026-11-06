# Deploying java-cicd-app to AWS EKS

Pipeline: GitHub Actions -> Gitleaks -> Maven test -> Docker build -> Amazon ECR -> kubectl deploy to EKS (no Ansible).
AWS auth from GitHub uses OIDC (no long-lived access keys stored).

## Prerequisites (on your machine)
AWS CLI v2, eksctl, kubectl, and `aws configure` done with an admin-capable user.

## 1. One-time AWS setup
    bash scripts/aws-setup.sh
Creates the ECR repo, the EKS cluster (ap-south-1), the GitHub OIDC provider, an IAM role for the
pipeline, and gives that role access to the cluster. It prints the role ARN at the end.

## 2. Add the GitHub secret
Repo -> Settings -> Secrets and variables -> Actions -> New secret:
`AWS_ROLE_ARN` = the ARN printed by the script.

## 3. Push to main
    git add . && git commit -m "Add EKS pipeline" && git push
Watch the Actions tab. The last step prints the NLB URL; open it (give DNS ~2-3 min) and /health.

## 4. Demo a change + redeploy
Edit the string in HelloController (e.g. Version 1.1), update HelloControllerTest to match, push.
The pipeline builds a new image tagged with the commit SHA and does a zero-downtime rolling update.

## Useful commands
    aws eks update-kubeconfig --name java-cicd-cluster --region ap-south-1
    kubectl get pods,svc -n java-cicd
    kubectl rollout history deployment/java-cicd-app -n java-cicd
    kubectl rollout undo deployment/java-cicd-app -n java-cicd

## Clean up (EKS costs money while it runs)
    kubectl delete namespace java-cicd        # removes the load balancer first
    eksctl delete cluster -f eks/cluster.yaml
    aws ecr delete-repository --repository-name java-cicd-app --region ap-south-1 --force

## Notes
- Region/names live in `.github/workflows/ci-cd.yml`, `eks/cluster.yaml`, `scripts/aws-setup.sh`, and the two JSON policies. Change them together if you rename anything.
- If your repo name or branch differs, edit the `sub` condition in `eks/github-oidc-trust-policy.json`.
