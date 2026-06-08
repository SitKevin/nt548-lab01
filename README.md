# NT548 - Bài tập thực hành 02

Repository này triển khai yêu cầu Lab02 của môn NT548: quản lý hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins.

Nội dung chính:

- Terraform triển khai hạ tầng AWS và tự động kiểm tra bằng GitHub Actions + Checkov.
- CloudFormation triển khai hạ tầng AWS và tự động hóa bằng AWS CodeBuild + CodePipeline.
- Jenkins CI/CD cho ứng dụng microservices chạy bằng Docker và Kubernetes, có tích hợp SonarQube và Trivy.

## Cấu trúc mã nguồn

```text
.
├── .github/workflows/
│   └── terraform.yml
├── cloudformation/
│   ├── infrastructure.yaml
│   ├── codepipeline.yaml
│   ├── buildspec.yml
│   └── .taskcat.yml
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── network/
│       ├── security/
│       └── ec2/
├── microservices/
│   ├── api-gateway/
│   └── orders-service/
├── k8s/
│   ├── namespace.yaml
│   ├── api-gateway.yaml
│   └── orders-service.yaml
├── docker-compose.yml
├── Jenkinsfile
├── sonar-project.properties
└── README.md
```

## 1. Terraform + GitHub Actions + Checkov

Terraform triển khai hạ tầng AWS nền tảng gồm:

- VPC
- Public subnet và private subnet
- Internet Gateway
- NAT Gateway
- Public route table và private route table
- Public EC2 và private EC2
- Security Groups cho public/private EC2

Các tài nguyên Terraform được chia thành module:

- `terraform/modules/network`: VPC, subnet, Internet Gateway, NAT Gateway, route tables.
- `terraform/modules/security`: Security Groups.
- `terraform/modules/ec2`: EC2 instances, IAM role/profile, hardening metadata và EBS.

Chạy kiểm tra local:

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Nếu muốn deploy thật lên AWS:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Sửa `terraform.tfvars`:

```hcl
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
key_name         = "YOUR_KEY_PAIR_NAME"
```

Sau đó chạy:

```bash
terraform apply
terraform output
```

GitHub Actions workflow nằm tại:

```text
.github/workflows/terraform.yml
```

Workflow tự động chạy khi push lên `main` hoặc `lab2`, gồm:

- `terraform fmt -check -recursive`
- `terraform init`
- `terraform validate`
- Checkov scan
- Terraform plan/apply khi chạy thủ công bằng `workflow_dispatch`

Các GitHub Secrets cần có nếu muốn chạy plan/apply trên GitHub Actions:

- `AWS_ROLE_TO_ASSUME`: IAM Role ARN cho GitHub OIDC.
- `ALLOWED_SSH_CIDR`: IP public được phép SSH vào public EC2, ví dụ `113.x.x.x/32`.
- `EC2_KEY_NAME`: tên EC2 Key Pair đã tồn tại trên AWS.

## 2. CloudFormation + CodeBuild + CodePipeline

Template hạ tầng CloudFormation nằm tại:

```text
cloudformation/infrastructure.yaml
```

Template này tạo cùng kiến trúc hạ tầng như Terraform:

- VPC
- Public/private subnet
- Internet Gateway
- NAT Gateway
- Route tables
- Security Groups
- Public/private EC2

Kiểm tra CloudFormation template bằng `cfn-lint`:

```bash
python3 -m venv /tmp/nt548-cfnlint
. /tmp/nt548-cfnlint/bin/activate
pip install "setuptools<81" cfn-lint taskcat
cfn-lint cloudformation/infrastructure.yaml cloudformation/codepipeline.yaml
```

Chạy Taskcat local:

```bash
cd cloudformation
taskcat test run
taskcat test clean nt548-lab02-cloudformation
```

Lưu ý: Taskcat sẽ tạo stack thật trên AWS, có thể phát sinh chi phí. Sau khi chụp minh chứng, cần dọn tài nguyên test.

Tạo CodePipeline stack:

```bash
aws cloudformation deploy \
  --template-file cloudformation/codepipeline.yaml \
  --stack-name nt548-lab02-pipeline \
  --region ap-southeast-1 \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=nt548-lab02 \
    RepositoryName=nt548-lab02 \
    BranchName=main \
    AllowedSshCidr=YOUR_PUBLIC_IP/32 \
    KeyName=YOUR_KEY_PAIR_NAME
```

Sau khi stack tạo xong, lấy CodeCommit clone URL:

```bash
aws cloudformation describe-stacks \
  --stack-name nt548-lab02-pipeline \
  --region ap-southeast-1 \
  --query "Stacks[0].Outputs" \
  --output table
```

Cấu hình Git credential cho CodeCommit:

```bash
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
```

Push source lên CodeCommit:

```bash
git remote add codecommit CODECOMMIT_CLONE_URL
git push codecommit lab2:main
```

Pipeline gồm 3 stage:

1. Source: lấy source từ CodeCommit.
2. Build: CodeBuild chạy `cfn-lint` và `taskcat`.
3. Deploy: CloudFormation deploy stack hạ tầng.

## 3. Jenkins CI/CD cho microservices

Ứng dụng microservices gồm hai service FastAPI:

- `api-gateway`: endpoint `/health`, `/orders`.
- `orders-service`: endpoint `/health`, `/orders`.

Chạy local bằng Docker Compose:

```bash
docker-compose up --build
```

Kiểm tra API:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/orders
curl http://localhost:8001/health
curl http://localhost:8001/orders
```

Chạy unit test:

```bash
cd microservices/api-gateway
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
pytest
deactivate

cd ../orders-service
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
pytest
deactivate
```

## 4. Kubernetes local bằng kind

Cài `kubectl` và `kind` nếu máy chưa có:

```bash
sudo snap install kubectl --classic
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Tạo cluster:

```bash
kind create cluster --name nt548-lab02
kubectl get nodes
```

Build và load image vào kind:

```bash
docker build -t nt548/api-gateway:latest microservices/api-gateway
docker build -t nt548/orders-service:latest microservices/orders-service

kind load docker-image nt548/api-gateway:latest --name nt548-lab02
kind load docker-image nt548/orders-service:latest --name nt548-lab02
```

Deploy lên Kubernetes:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/orders-service.yaml
kubectl apply -f k8s/api-gateway.yaml
kubectl -n nt548-lab02 get pods,svc
```

Test API qua port-forward:

```bash
kubectl -n nt548-lab02 port-forward svc/api-gateway 8080:8000
```

Mở terminal khác:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/orders
```

## 5. Jenkins

Jenkins pipeline nằm trong:

```text
Jenkinsfile
```

Các stage chính:

- Install and test
- SonarQube analysis
- Build images
- Security scan bằng Trivy
- Deploy to Kubernetes

Pipeline hiện được cấu hình để:

- Build Docker image cho `api-gateway` và `orders-service`.
- Chạy Trivy bằng Docker image `aquasec/trivy`.
- Nếu phát hiện cluster kind tên `nt548-lab02`, tự động load image vào cluster trước khi deploy.

Chạy Jenkins bằng Docker:

```bash
docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/.kube:/root/.kube \
  -v /usr/local/bin/kind:/usr/local/bin/kind \
  -v /snap/bin/kubectl:/usr/local/bin/kubectl \
  jenkins/jenkins:lts
```

Lấy password Jenkins lần đầu:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Cài thêm công cụ trong Jenkins container nếu cần:

```bash
docker exec -u root jenkins bash -lc "apt-get update && apt-get install -y docker.io python3 python3-venv curl"
```

Tạo Jenkins credential:

- Kind: `Secret file`
- ID: `kubeconfig`
- File: chọn file kubeconfig từ máy local, thường là `/home/sitkevin/.kube/config`

Cấu hình SonarQube server trong Jenkins:

- Name: `sonarqube`
- Server URL: URL SonarQube mà Jenkins container truy cập được
- Token: SonarQube token dạng `Secret text`

Tạo Pipeline job:

- Definition: `Pipeline script from SCM`
- SCM: Git
- Repository URL: `https://github.com/SitKevin/nt548-lab01.git`
- Branch: `*/lab2`
- Script Path: `Jenkinsfile`

## 6. SonarQube

Chạy SonarQube bằng Docker:

```bash
docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  sonarqube:community
```

Mở:

```text
http://localhost:9000
```

Tài khoản mặc định:

```text
admin / admin
```

Sau khi đăng nhập, tạo token tại:

```text
My Account -> Security -> Generate Token
```

Nếu SonarQube bị offline, kiểm tra dung lượng ổ đĩa:

```bash
df -h /
docker system df
```

SonarQube dùng Elasticsearch nên cần dung lượng trống đủ lớn. Nếu ổ đĩa gần đầy, cần dọn Docker image/container không dùng:

```bash
docker container prune -f
docker image prune -a -f
```

## 7. Minh chứng cần chụp cho báo cáo

Các ảnh nên có:

- GitHub Actions workflow pass.
- Checkov scan pass hoặc có log scan.
- Terraform validate/plan/apply.
- `cfn-lint` không báo lỗi.
- CodePipeline có 3 stage Source, Build, Deploy.
- CodeBuild build succeeded, log có `cfn-lint` và `taskcat`.
- Docker Compose chạy được hai service.
- Pytest pass cho hai service.
- Kubernetes pods/services ở trạng thái Running.
- Jenkins pipeline các stage xanh.
- SonarQube dashboard hoặc kết quả analysis.
- Trivy scan log.

## 8. Dọn dẹp tài nguyên

Terraform:

```bash
cd terraform
terraform destroy
```

CloudFormation:

```bash
aws cloudformation delete-stack --stack-name nt548-lab02-infra --region ap-southeast-1
aws cloudformation delete-stack --stack-name nt548-lab02-pipeline --region ap-southeast-1
```

Kubernetes:

```bash
kubectl delete namespace nt548-lab02
```

Docker local:

```bash
docker stop jenkins sonarqube
docker rm jenkins sonarqube
```
