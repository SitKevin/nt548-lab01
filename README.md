# NT548 - Bai tap thuc hanh 02

Repo nay mo rong bai lab01 de dap ung lab02: Terraform + GitHub Actions + Checkov, CloudFormation + CodeBuild/CodePipeline + cfn-lint/Taskcat, va Jenkins CI/CD cho ung dung microservices Docker/Kubernetes.

## Cau truc

```text
.
├── .github/workflows/terraform.yml
├── cloudformation/
│   ├── infrastructure.yaml
│   ├── codepipeline.yaml
│   ├── buildspec.yml
│   └── .taskcat.yml
├── terraform/
│   ├── main.tf
│   └── modules/
├── microservices/
│   ├── api-gateway/
│   └── orders-service/
├── k8s/
│   ├── namespace.yaml
│   ├── api-gateway.yaml
│   └── orders-service.yaml
├── docker-compose.yml
├── Jenkinsfile
└── sonar-project.properties
```

## 1. Terraform + GitHub Actions + Checkov

Terraform tao lai ha tang cua lab01:

- VPC, public subnet, private subnet
- Internet Gateway, NAT Gateway
- Public/private route tables
- Public EC2, private EC2
- Security Groups cho SSH vao public EC2 va SSH tu public EC2 sang private EC2

Chay local:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# sua allowed_ssh_cidr va key_name
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

GitHub Actions workflow nam o `.github/workflows/terraform.yml`.

Can tao cac GitHub secrets:

- `AWS_ROLE_TO_ASSUME`: IAM role ARN cho GitHub OIDC.
- `ALLOWED_SSH_CIDR`: IP public cua ban, vi du `113.x.x.x/32`.
- `EC2_KEY_NAME`: ten EC2 Key Pair da ton tai tren AWS.

Workflow tu dong chay `terraform fmt`, `terraform validate`, Checkov scan. Khi chay thu cong bang `workflow_dispatch`, workflow co the chay `plan` va `apply`.

## 2. CloudFormation + CodeBuild + CodePipeline

Template ha tang nam o `cloudformation/infrastructure.yaml`, gom cung cac thanh phan nhu Terraform.

Kiem tra local:

```bash
pip install cfn-lint taskcat
cfn-lint cloudformation/infrastructure.yaml
```

Neu muon chay Taskcat local, sua `cloudformation/.taskcat.yml`:

```yaml
ProjectName: nt548-lab02-taskcat
AllowedSshCidr: YOUR_PUBLIC_IP/32
KeyName: YOUR_KEY_PAIR_NAME
```

Sau do chay:

```bash
taskcat test run
taskcat test clean
```

Tao stack CodePipeline:

```bash
aws cloudformation deploy \
  --template-file cloudformation/codepipeline.yaml \
  --stack-name nt548-lab02-pipeline \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=nt548-lab02 \
    RepositoryName=nt548-lab02 \
    BranchName=main \
    AllowedSshCidr=YOUR_PUBLIC_IP/32 \
    KeyName=YOUR_KEY_PAIR_NAME
```

Sau khi stack tao xong, push source len CodeCommit repository duoc output tu stack. Pipeline se:

1. Lay source tu CodeCommit.
2. Chay CodeBuild voi `cfn-lint` va `taskcat`.
3. Deploy `cloudformation/infrastructure.yaml` bang CloudFormation.

## 3. Jenkins CI/CD cho microservices

Ung dung mau gom hai service FastAPI:

- `api-gateway`: endpoint `/health`, `/orders`.
- `orders-service`: endpoint `/health`, `/orders`.

Chay bang Docker Compose:

```bash
docker compose up --build
# neu Docker cua may dung compose ban cu:
docker-compose up --build
curl http://localhost:8000/health
curl http://localhost:8000/orders
curl http://localhost:8001/orders
```

Chay test local:

```bash
cd microservices/api-gateway
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
pytest

cd ../orders-service
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
pytest
```

Deploy Kubernetes:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/orders-service.yaml
kubectl apply -f k8s/api-gateway.yaml
kubectl -n nt548-lab02 get pods,svc
```

Jenkins pipeline nam o `Jenkinsfile`, gom cac stage:

- Install and test
- SonarQube analysis
- Build Docker images
- Trivy security scan
- Deploy to Kubernetes

Can cau hinh Jenkins:

- Cai plugin Pipeline, SonarQube Scanner, Docker Pipeline neu can.
- Tao Jenkins credential file co ID `kubeconfig`.
- Tao SonarQube server trong Jenkins voi name `sonarqube`.
- Cai CLI tren Jenkins agent: `python3`, `docker`, `kubectl`, `sonar-scanner`, `trivy`.

## Don dep tai nguyen

Terraform:

```bash
cd terraform
terraform destroy
```

CloudFormation:

```bash
aws cloudformation delete-stack --stack-name nt548-lab02-infra
aws cloudformation delete-stack --stack-name nt548-lab02-pipeline
```
