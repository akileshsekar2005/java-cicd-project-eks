# Java CI/CD on Amazon EKS - setup notes

This project is configured for:
- Java 17 / Spring Boot
- GitHub Actions CI/CD
- Amazon ECR
- Amazon EKS Auto Mode
- Public AWS Network Load Balancer (NLB)

## Important
The GitHub Actions workflow assumes:
- AWS Region: `ap-south-1`
- ECR repository: `java-cicd-app`
- EKS cluster: `java-cicd-cluster`
- GitHub Actions secret: `AWS_ROLE_ARN`

The EKS cluster must be created with EKS Auto Mode enabled. The GitHub IAM role must have ECR push permissions, `eks:DescribeCluster`, and an EKS access entry associated with `AmazonEKSClusterAdminPolicy` (for a quick demo; reduce permissions for production).

The workflow uses Maven Wrapper and passes the JAR between jobs as an artifact. It builds the Docker image with `-f src/main/Dockerfile`, then deploys the immutable commit-SHA image to Kubernetes.

See the setup instructions in the ChatGPT conversation for AWS account, GitHub OIDC, IAM, cluster, and deployment steps.
