# BÁO CÁO THỰC HÀNH 02

**Môn học:** Công nghệ DevOps và Ứng dụng  
**Mã môn học:** NT548  
**Tên chủ đề:** Quản lý và triển khai hạ tầng AWS và ứng dụng microservices với Terraform, CloudFormation, GitHub Actions, AWS CodePipeline và Jenkins  
**Giảng viên hướng dẫn:** ThS. Lê Anh Tuấn  
**Lớp:** NT548.Q21  
**Nhóm:** `<Điền số nhóm>`  
**Ngày báo cáo:** `<Điền ngày nộp>`

## 1. Thông Tin Thành Viên

| STT | Họ và tên | MSSV | Công việc thực hiện | Điểm tự đánh giá |
|---:|---|---|---|---|
| 1 | Sit Khải Đông | 23520299 | Terraform, GitHub Actions, Checkov | 100% |
| 2 | Võ Minh An | 23520033 | CloudFormation, CodeBuild, CodePipeline | 100% |
| 3 | Nguyễn Gia Bảo | 23520122 | Jenkins, SonarQube, Trivy, Docker | 100% |
| 4 | Vũ Lê Phát Tài | 24521563 | Kubernetes, microservices, tài liệu báo cáo | 100% |

**Link GitHub:** https://github.com/SitKevin/nt548-lab01

## 2. Mục Tiêu Bài Thực Hành

Bài thực hành 02 yêu cầu quản lý và triển khai hạ tầng AWS, đồng thời xây dựng quy trình CI/CD cho ứng dụng microservices. Nội dung chính gồm ba nhóm yêu cầu:

1. Dùng Terraform triển khai hạ tầng AWS nền tảng gồm VPC, Route Tables, NAT Gateway, EC2 và Security Groups, tự động hóa bằng GitHub Actions và tích hợp Checkov để kiểm tra tuân thủ/bảo mật.
2. Dùng CloudFormation triển khai cùng hạ tầng AWS, sử dụng CodeBuild để chạy `cfn-lint` và Taskcat, sau đó tự động hóa build/deploy bằng AWS CodePipeline từ CodeCommit.
3. Dùng Jenkins để tự động hóa build, test và deploy ứng dụng microservices trên Docker/Kubernetes, tích hợp SonarQube và công cụ kiểm tra bảo mật container.

## 3. Tổng Quan Giải Pháp

Nhóm triển khai bài lab theo mô hình kết hợp Infrastructure as Code và CI/CD:

- **Terraform pipeline:** GitHub Actions kiểm tra format, validate, scan Checkov và có thể chạy `plan/apply` khi được kích hoạt thủ công.
- **CloudFormation pipeline:** AWS CodePipeline lấy source từ CodeCommit, CodeBuild kiểm tra template bằng `cfn-lint` và Taskcat, sau đó deploy stack CloudFormation.
- **Microservices pipeline:** Jenkins chạy unit test cho từng service, phân tích chất lượng mã bằng SonarQube, build Docker image, scan image bằng Trivy và deploy lên Kubernetes.

**Hình 1. Sơ đồ tổng quan quy trình Lab02**  
`[Chèn sơ đồ gồm GitHub Actions -> Terraform -> AWS; CodeCommit -> CodePipeline -> CodeBuild -> CloudFormation -> AWS; Jenkins -> Docker/SonarQube/Trivy -> Kubernetes]`

## 4. Cấu Trúc Mã Nguồn

```text
.
├── .github/workflows/
│   └── terraform.yml
├── terraform/
│   ├── main.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── network/
│       ├── security/
│       └── ec2/
├── cloudformation/
│   ├── infrastructure.yaml
│   ├── codepipeline.yaml
│   ├── buildspec.yml
│   └── .taskcat.yml
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

## 5. Yêu Cầu 1: Terraform, GitHub Actions Và Checkov

### 5.1. Mục Tiêu

Yêu cầu đầu tiên của Lab02 là sử dụng Terraform để triển khai hạ tầng AWS nền tảng, bao gồm:

- VPC
- Route Tables
- NAT Gateway
- EC2
- Security Groups

Sau đó tự động hóa quy trình kiểm tra/triển khai bằng GitHub Actions và tích hợp Checkov để kiểm tra bảo mật mã Terraform.

### 5.2. Terraform Infrastructure

Terraform được tổ chức thành các module để tách rõ trách nhiệm:

| Module | File | Vai trò |
|---|---|---|
| `network` | `terraform/modules/network` | Tạo VPC, public/private subnet, Internet Gateway, NAT Gateway, route tables. |
| `security` | `terraform/modules/security` | Tạo Security Group cho public EC2 và private EC2. |
| `ec2` | `terraform/modules/ec2` | Tạo public EC2 và private EC2. |

Root module gọi ba module trên trong `terraform/main.tf`. Các output quan trọng gồm:

- `vpc_id`
- `public_subnet_id`
- `private_subnet_id`
- `public_instance_public_ip`
- `private_instance_private_ip`

### 5.3. Bảo Mật Trong Terraform

Các cấu hình bảo mật chính:

- Public EC2 Security Group chỉ mở SSH port 22 từ biến `allowed_ssh_cidr`.
- Private EC2 Security Group chỉ mở SSH port 22 từ Security Group của public EC2.
- Private EC2 không gán public IP.
- EC2 bật IMDSv2 bằng `metadata_options.http_tokens = "required"`.
- Root block device của EC2 được mã hóa.
- EC2 bật detailed monitoring.

Đoạn cấu hình EC2 bảo mật:

```hcl
metadata_options {
  http_endpoint = "enabled"
  http_tokens   = "required"
}

root_block_device {
  encrypted = true
}
```

### 5.4. GitHub Actions Workflow

Workflow được đặt tại:

```text
.github/workflows/terraform.yml
```

Workflow thực hiện các bước:

1. Checkout source code.
2. Cài Terraform.
3. Chạy `terraform fmt -check -recursive`.
4. Chạy `terraform init`.
5. Chạy `terraform validate`.
6. Chạy Checkov để scan Terraform.
7. Khi chạy thủ công bằng `workflow_dispatch`, workflow có thể chạy `terraform plan`.
8. Nếu input `apply=true`, workflow chạy `terraform apply -auto-approve`.

Workflow sử dụng GitHub secrets:

| Secret | Ý nghĩa |
|---|---|
| `AWS_ROLE_TO_ASSUME` | IAM Role ARN cho GitHub Actions OIDC. |
| `ALLOWED_SSH_CIDR` | IP public được phép SSH vào public EC2, dạng `/32`. |
| `EC2_KEY_NAME` | Tên EC2 Key Pair đã tồn tại trên AWS. |

### 5.5. Checkov

Checkov được tích hợp trong GitHub Actions bằng action:

```yaml
uses: bridgecrewio/checkov-action@v12
```

Checkov kiểm tra các lỗi phổ biến trong Terraform, ví dụ:

- Security Group mở port nguy hiểm ra Internet.
- EC2 chưa bật IMDSv2.
- Volume chưa mã hóa.
- Cấu hình IAM hoặc network không an toàn.

Trong workflow, Checkov được đặt `soft_fail: true` để pipeline vẫn tiếp tục chạy trong môi trường học tập, nhưng kết quả scan vẫn được ghi nhận để nhóm phân tích và sửa lỗi.

**Hình 2. GitHub Actions chạy Terraform validate và Checkov**  
`[Chèn ảnh workflow GitHub Actions passed]`

**Hình 3. Kết quả Checkov scan**  
`[Chèn ảnh log Checkov trong GitHub Actions]`

### 5.6. Cách Chạy Terraform Local

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Sửa `terraform.tfvars`:

```hcl
aws_region          = "ap-southeast-1"
project_name        = "nt548-lab01"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"
availability_zone   = "ap-southeast-1a"
allowed_ssh_cidr    = "<IP_PUBLIC_CUA_NHOM>/32"
key_name            = "<TEN_KEY_PAIR>"
```

Chạy:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

**Hình 4. Terraform apply thành công**  
`[Chèn ảnh terminal terraform apply complete]`

## 6. Yêu Cầu 2: CloudFormation, CodeBuild, Taskcat Và CodePipeline

### 6.1. Mục Tiêu

Yêu cầu thứ hai là dùng CloudFormation để triển khai các dịch vụ AWS tương tự phần Terraform, đồng thời tự động hóa quy trình build/deploy bằng AWS CodePipeline từ source trên CodeCommit. CodeBuild cần tích hợp:

- `cfn-lint` để kiểm tra cú pháp và best practices của template CloudFormation.
- Taskcat để kiểm thử template bằng cách tạo stack thực tế trên AWS.

### 6.2. CloudFormation Infrastructure Template

Template hạ tầng chính:

```text
cloudformation/infrastructure.yaml
```

Template này tạo:

| Thành phần | CloudFormation resource |
|---|---|
| VPC | `AWS::EC2::VPC` |
| Internet Gateway | `AWS::EC2::InternetGateway` |
| Public subnet | `AWS::EC2::Subnet` |
| Private subnet | `AWS::EC2::Subnet` |
| Elastic IP | `AWS::EC2::EIP` |
| NAT Gateway | `AWS::EC2::NatGateway` |
| Route Table | `AWS::EC2::RouteTable` |
| Route | `AWS::EC2::Route` |
| Security Group | `AWS::EC2::SecurityGroup` |
| EC2 Instance | `AWS::EC2::Instance` |

Template sử dụng Parameters để dễ tái sử dụng:

- `ProjectName`
- `VpcCidr`
- `PublicSubnetCidr`
- `PrivateSubnetCidr`
- `AvailabilityZone`
- `AllowedSshCidr`
- `KeyName`
- `LatestAmiId`
- `InstanceType`

### 6.3. Kiểm Tra Template Bằng cfn-lint

Lệnh kiểm tra local:

```bash
pip install cfn-lint
cfn-lint cloudformation/infrastructure.yaml
```

Kết quả mong đợi: không có lỗi cú pháp hoặc lỗi cấu hình nghiêm trọng.

**Hình 5. cfn-lint chạy thành công**  
`[Chèn ảnh cfn-lint không báo lỗi]`

### 6.4. Taskcat

File cấu hình Taskcat:

```text
cloudformation/.taskcat.yml
```

Taskcat tạo stack thử nghiệm ở region `ap-southeast-1` để kiểm tra template có thể deploy thật trên AWS. Các tham số như `AllowedSshCidr` và `KeyName` được truyền vào để stack có đủ điều kiện tạo EC2.

Lệnh chạy local:

```bash
pip install taskcat
taskcat test run
taskcat test clean
```

**Hình 6. Taskcat test run thành công**  
`[Chèn ảnh Taskcat tạo stack test thành công]`

### 6.5. CodeBuild

File buildspec:

```text
cloudformation/buildspec.yml
```

Buildspec thực hiện:

1. Cài Python dependencies.
2. Cài `cfn-lint` và `taskcat`.
3. Chạy `cfn-lint cloudformation/infrastructure.yaml`.
4. Truyền `ALLOWED_SSH_CIDR` và `KEY_NAME` vào Taskcat config.
5. Chạy `taskcat test run`.

Nội dung chính:

```yaml
phases:
  install:
    commands:
      - pip install cfn-lint taskcat
  build:
    commands:
      - cfn-lint cloudformation/infrastructure.yaml
      - taskcat test run
```

**Hình 7. CodeBuild chạy cfn-lint và Taskcat thành công**  
`[Chèn ảnh CodeBuild build succeeded]`

### 6.6. CodePipeline Và CodeCommit

Template tạo pipeline:

```text
cloudformation/codepipeline.yaml
```

Template này tạo:

- CodeCommit repository.
- S3 artifact bucket.
- IAM role cho CodeBuild.
- IAM role cho CodePipeline.
- IAM role cho CloudFormation deploy.
- CodeBuild project.
- CodePipeline gồm 3 stage: Source, Build, Deploy.

Luồng pipeline:

| Stage | Dịch vụ | Vai trò |
|---|---|---|
| Source | CodeCommit | Lấy source code từ branch `main`. |
| Build | CodeBuild | Chạy `cfn-lint` và Taskcat. |
| Deploy | CloudFormation | Deploy stack hạ tầng AWS. |

Deploy pipeline:

```bash
aws cloudformation deploy \
  --template-file cloudformation/codepipeline.yaml \
  --stack-name nt548-lab02-pipeline \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    ProjectName=nt548-lab02 \
    RepositoryName=nt548-lab02 \
    BranchName=main \
    AllowedSshCidr=<IP_PUBLIC_CUA_NHOM>/32 \
    KeyName=<TEN_KEY_PAIR>
```

Sau khi stack pipeline tạo xong, push source lên CodeCommit:

```bash
git remote add codecommit <CODECOMMIT_CLONE_URL>
git push codecommit main
```

**Hình 8. CodePipeline có 3 stage Source, Build, Deploy**  
`[Chèn ảnh AWS CodePipeline]`

**Hình 9. CloudFormation stack được deploy bởi CodePipeline**  
`[Chèn ảnh stack nt548-lab02-infra CREATE_COMPLETE]`

## 7. Yêu Cầu 3: Jenkins CI/CD Cho Microservices

### 7.1. Mục Tiêu

Yêu cầu thứ ba là dùng Jenkins hoặc dịch vụ tương tự để quản lý quy trình CI/CD cho ứng dụng microservices trên Docker và Kubernetes. Pipeline cần:

- Build ứng dụng microservices.
- Chạy test.
- Build Docker image.
- Deploy lên Kubernetes.
- Tích hợp SonarQube để kiểm tra chất lượng mã nguồn.
- Có thể tích hợp công cụ bảo mật như Trivy hoặc Snyk.

### 7.2. Ứng Dụng Microservices

Nhóm xây dựng ứng dụng mẫu gồm hai service FastAPI:

| Service | Thư mục | Endpoint | Vai trò |
|---|---|---|---|
| API Gateway | `microservices/api-gateway` | `/health`, `/orders` | Nhận request từ người dùng và gọi orders service. |
| Orders Service | `microservices/orders-service` | `/health`, `/orders` | Quản lý dữ liệu đơn hàng mẫu. |

Kiến trúc ứng dụng:

```text
Client
  |
  v
api-gateway:8000
  |
  v
orders-service:8000
```

**Hình 10. Sơ đồ microservices**  
`[Chèn sơ đồ Client -> API Gateway -> Orders Service]`

### 7.3. Chạy Local Bằng Docker Compose

File Docker Compose:

```text
docker-compose.yml
```

Chạy ứng dụng:

```bash
docker-compose up --build
```

Kiểm tra:

```bash
curl http://localhost:8000/health
curl http://localhost:8000/orders
curl http://localhost:8001/orders
```

Kết quả mong đợi:

- API Gateway trả về trạng thái `ok`.
- API Gateway gọi được Orders Service.
- Orders Service trả về danh sách đơn hàng mẫu.

**Hình 11. Docker Compose chạy hai service thành công**  
`[Chèn ảnh docker-compose up và curl endpoint]`

### 7.4. Unit Test

Mỗi service có thư mục `tests/` và sử dụng `pytest`.

Chạy test API Gateway:

```bash
cd microservices/api-gateway
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
pytest
```

Chạy test Orders Service:

```bash
cd microservices/orders-service
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
pytest
```

Kết quả kiểm tra trong quá trình thực hiện:

```text
api-gateway: 1 passed
orders-service: 2 passed
```

**Hình 12. Unit test microservices thành công**  
`[Chèn ảnh pytest passed]`

### 7.5. Kubernetes Manifests

Các manifest Kubernetes nằm trong thư mục:

```text
k8s/
├── namespace.yaml
├── api-gateway.yaml
└── orders-service.yaml
```

Các tài nguyên Kubernetes:

| File | Tài nguyên |
|---|---|
| `namespace.yaml` | Namespace `nt548-lab02` |
| `orders-service.yaml` | Deployment và Service cho Orders Service |
| `api-gateway.yaml` | Deployment và NodePort Service cho API Gateway |

Deploy Kubernetes:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/orders-service.yaml
kubectl apply -f k8s/api-gateway.yaml
kubectl -n nt548-lab02 get pods,svc
```

Kết quả mong đợi:

- Pod `api-gateway` ở trạng thái `Running`.
- Pod `orders-service` ở trạng thái `Running`.
- Service `api-gateway` expose qua NodePort `30080`.
- Service `orders-service` chỉ dùng nội bộ cluster.

**Hình 13. Kubernetes pods và services running**  
`[Chèn ảnh kubectl get pods,svc]`

### 7.6. Jenkins Pipeline

Pipeline nằm trong:

```text
Jenkinsfile
```

Các stage chính:

| Stage | Công việc |
|---|---|
| Install and test | Cài dependency và chạy pytest cho từng service. |
| SonarQube analysis | Chạy `sonar-scanner` để phân tích chất lượng mã nguồn. |
| Build images | Build Docker image cho `api-gateway` và `orders-service`. |
| Security scan | Dùng Trivy scan image với mức HIGH/CRITICAL. |
| Deploy to Kubernetes | Apply manifest và cập nhật image trong deployment. |

Pipeline Jenkins:

```groovy
pipeline {
  agent any

  stages {
    stage('Install and test') { ... }
    stage('SonarQube analysis') { ... }
    stage('Build images') { ... }
    stage('Security scan') { ... }
    stage('Deploy to Kubernetes') { ... }
  }
}
```

**Hình 14. Jenkins pipeline chạy thành công**  
`[Chèn ảnh Jenkins các stage xanh/pass]`

### 7.7. SonarQube

File cấu hình:

```text
sonar-project.properties
```

Nội dung chính:

```properties
sonar.projectKey=nt548-lab02
sonar.projectName=NT548 Lab02 Microservices
sonar.sources=microservices
sonar.tests=microservices
sonar.test.inclusions=**/tests/**
sonar.python.version=3.11
```

SonarQube được dùng để:

- Phát hiện code smell.
- Kiểm tra maintainability.
- Kiểm tra reliability.
- Theo dõi bug hoặc vulnerability ở mức source code.

**Hình 15. SonarQube analysis result**  
`[Chèn ảnh dashboard SonarQube]`

### 7.8. Trivy Security Scan

Trong Jenkinsfile, Trivy được dùng để scan Docker image:

```bash
trivy image --exit-code 0 --severity HIGH,CRITICAL nt548/api-gateway:${BUILD_NUMBER}
trivy image --exit-code 0 --severity HIGH,CRITICAL nt548/orders-service:${BUILD_NUMBER}
```

Trong môi trường học tập, `--exit-code 0` giúp pipeline không bị fail ngay khi phát hiện vulnerability, nhưng log scan vẫn được giữ lại để phân tích. Khi triển khai production, có thể đổi thành `--exit-code 1` để chặn image có lỗi nghiêm trọng.

**Hình 16. Trivy scan Docker image**  
`[Chèn ảnh log Trivy trong Jenkins]`

## 8. Test Cases Tổng Hợp

### 8.1. Test Terraform

| Test case | Lệnh | Kết quả mong đợi |
|---|---|---|
| Format Terraform | `terraform fmt -check -recursive` | Không có file sai format. |
| Validate Terraform | `terraform validate` | Configuration valid. |
| Plan Terraform | `terraform plan` | Sinh execution plan thành công. |
| Apply Terraform | `terraform apply` | Tạo VPC, subnet, NAT, EC2, SG thành công. |
| Checkov | GitHub Actions Checkov step | Có report security scan. |

**Hình 17. Terraform test cases**  
`[Chèn ảnh terraform validate/plan hoặc GitHub Actions]`

### 8.2. Test CloudFormation

| Test case | Lệnh/Công cụ | Kết quả mong đợi |
|---|---|---|
| Validate template | `aws cloudformation validate-template` | Template hợp lệ. |
| cfn-lint | `cfn-lint cloudformation/infrastructure.yaml` | Không có lỗi lint nghiêm trọng. |
| Taskcat | `taskcat test run` | Stack test tạo thành công. |
| CodeBuild | CodePipeline Build stage | Build succeeded. |
| CodePipeline | Source, Build, Deploy | Pipeline succeeded. |

**Hình 18. CloudFormation/CodePipeline test cases**  
`[Chèn ảnh cfn-lint, Taskcat, CodePipeline succeeded]`

### 8.3. Test Microservices

| Test case | Lệnh | Kết quả mong đợi |
|---|---|---|
| Unit test API Gateway | `pytest` | Test passed. |
| Unit test Orders Service | `pytest` | Test passed. |
| Docker Compose | `docker-compose up --build` | Hai service chạy thành công. |
| API health | `curl http://localhost:8000/health` | Trả về `status: ok`. |
| Orders endpoint | `curl http://localhost:8000/orders` | Trả về danh sách orders. |
| Kubernetes deploy | `kubectl apply -f k8s/` | Pods running. |
| Jenkins pipeline | Jenkins build | Các stage pass. |
| SonarQube | `sonar-scanner` | Có report chất lượng mã. |
| Trivy | `trivy image ...` | Có report bảo mật image. |

**Hình 19. Microservices test cases**  
`[Chèn ảnh pytest, docker-compose, curl, kubectl, Jenkins]`

## 9. Kết Quả Đạt Được Theo Yêu Cầu Lab02

| Yêu cầu Lab02 | Kết quả thực hiện | Minh chứng |
|---|---|---|
| Terraform triển khai VPC, route tables, NAT Gateway, EC2, Security Groups | Đã có module Terraform `network`, `security`, `ec2` | `terraform/` |
| Tự động hóa Terraform bằng GitHub Actions | Đã có workflow validate/scan/plan/apply | `.github/workflows/terraform.yml` |
| Tích hợp Checkov | Đã tích hợp trong GitHub Actions | Checkov step |
| CloudFormation triển khai hạ tầng AWS | Đã có template infrastructure | `cloudformation/infrastructure.yaml` |
| CodeBuild tích hợp cfn-lint và Taskcat | Đã có `buildspec.yml` | CodeBuild logs |
| CodePipeline deploy từ CodeCommit | Đã có template tạo pipeline | `cloudformation/codepipeline.yaml` |
| Jenkins CI/CD cho microservices | Đã có Jenkinsfile gồm test, SonarQube, build, scan, deploy | `Jenkinsfile` |
| Docker cho microservices | Mỗi service có Dockerfile, có Docker Compose | `microservices/`, `docker-compose.yml` |
| Kubernetes deploy | Đã có manifest namespace, deployment, service | `k8s/` |
| SonarQube | Đã có cấu hình scanner | `sonar-project.properties` |
| Security scan tùy chọn | Đã tích hợp Trivy trong Jenkins | Jenkins security scan stage |

## 10. Khó Khăn Và Cách Khắc Phục

### 10.1. AWS Resource Dễ Bị Lẫn Khi Tài Khoản Có Nhiều Lab

Khi dùng chung một tài khoản AWS cho nhiều lần thực hành, các lệnh `describe-vpcs`, `describe-security-groups` hoặc `describe-route-tables` có thể hiển thị nhiều tài nguyên khác nhau. Nhóm khắc phục bằng cách đặt tag theo `project_name` và filter theo tag hoặc VPC ID khi kiểm tra.

### 10.2. Quản Lý Secret Trong CI/CD

Các thông tin như SSH CIDR, EC2 key pair, IAM role ARN không được hard-code trong workflow. Nhóm sử dụng GitHub Secrets và ParameterOverrides trong CodePipeline để truyền giá trị vào pipeline.

### 10.3. Kiểm Thử CloudFormation Tốn Chi Phí AWS

Taskcat tạo stack thật trên AWS nên có thể phát sinh chi phí, đặc biệt với NAT Gateway. Nhóm cần chạy `taskcat test clean` sau khi test và xóa stack không sử dụng.

### 10.4. Jenkins Cần Nhiều Công Cụ Trên Agent

Jenkins agent cần có `python3`, `docker`, `kubectl`, `sonar-scanner` và `trivy`. Nhóm ghi rõ các dependency này trong README để dễ tái lập môi trường.

### 10.5. NAT Gateway Có Chi Phí

NAT Gateway phát sinh chi phí theo thời gian chạy. Sau khi hoàn tất lab, nhóm cần chạy `terraform destroy` hoặc xóa CloudFormation stack để tránh tốn chi phí.

## 11. Kết Luận

Bài thực hành 02 đã xây dựng quy trình DevOps hoàn chỉnh cho cả hạ tầng AWS và ứng dụng microservices. Nhóm đã triển khai Infrastructure as Code bằng Terraform và CloudFormation, đồng thời tự động hóa kiểm tra, build, scan và deploy bằng GitHub Actions, AWS CodeBuild, AWS CodePipeline và Jenkins.

Với Terraform, hệ thống được chia thành module rõ ràng và được kiểm tra tự động bằng GitHub Actions cùng Checkov. Với CloudFormation, template hạ tầng được kiểm tra bằng `cfn-lint`, Taskcat và được deploy qua CodePipeline. Với ứng dụng microservices, Jenkins tự động chạy test, phân tích chất lượng mã bằng SonarQube, build Docker image, scan bảo mật bằng Trivy và deploy lên Kubernetes.

Qua bài lab, nhóm hiểu rõ hơn cách kết hợp IaC, CI/CD, kiểm thử bảo mật và triển khai container trong một quy trình DevOps thực tế.

## 12. Checklist Ảnh Minh Chứng Cần Chèn

| STT | Ảnh minh chứng | Phần báo cáo |
|---:|---|---|
| 1 | Sơ đồ tổng quan Lab02 | Tổng quan giải pháp |
| 2 | GitHub Actions workflow pass | Terraform + GitHub Actions |
| 3 | Checkov scan result | Terraform + Checkov |
| 4 | Terraform apply/outputs | Terraform |
| 5 | cfn-lint pass | CloudFormation |
| 6 | Taskcat test run pass | CloudFormation |
| 7 | CodeBuild succeeded | CodeBuild |
| 8 | CodePipeline Source/Build/Deploy succeeded | CodePipeline |
| 9 | CloudFormation stack CREATE_COMPLETE | CloudFormation deploy |
| 10 | Docker Compose chạy hai services | Microservices |
| 11 | Pytest passed cho hai services | Unit test |
| 12 | SonarQube dashboard | Code quality |
| 13 | Trivy scan logs | Security scan |
| 14 | Jenkins pipeline all stages passed | Jenkins CI/CD |
| 15 | Kubernetes pods/services running | Kubernetes deploy |
| 16 | Curl API Gateway `/health` và `/orders` | Kiểm thử ứng dụng |

## 13. Phụ Lục Lệnh Kiểm Tra Nhanh

### Terraform

```bash
cd terraform
terraform fmt -recursive
terraform validate
terraform plan
```

### Checkov Local

```bash
pip install checkov
checkov -d terraform
```

### CloudFormation

```bash
cfn-lint cloudformation/infrastructure.yaml
taskcat test run
taskcat test clean
```

### Docker Compose

```bash
docker-compose up --build
curl http://localhost:8000/health
curl http://localhost:8000/orders
```

### Kubernetes

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/orders-service.yaml
kubectl apply -f k8s/api-gateway.yaml
kubectl -n nt548-lab02 get pods,svc
```

### Jenkins

```text
Tạo Jenkins pipeline job trỏ đến repository GitHub.
Pipeline script lấy từ Jenkinsfile.
Cấu hình SonarQube server tên: sonarqube.
Cấu hình credential file ID: kubeconfig.
Chạy Build Now và kiểm tra từng stage.
```

## 14. Phụ Lục Dọn Dẹp Tài Nguyên

### Terraform Destroy

```bash
cd terraform
terraform destroy
```

### CloudFormation Delete

```bash
aws cloudformation delete-stack \
  --stack-name nt548-lab02-infra \
  --region ap-southeast-1

aws cloudformation delete-stack \
  --stack-name nt548-lab02-pipeline \
  --region ap-southeast-1
```

### Kubernetes Delete

```bash
kubectl delete namespace nt548-lab02
```
