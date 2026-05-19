# NT548 - Lab 01  
## AWS Infrastructure as Code với Terraform & CloudFormation

---

# Giới thiệu
Dự án này triển khai hạ tầng AWS tự động bằng phương pháp **Infrastructure as Code (IaC)** sử dụng:

- Terraform
- AWS CloudFormation

Mục tiêu của bài lab là xây dựng và quản lý hạ tầng AWS theo hướng tự động hóa, dễ mở rộng, dễ bảo trì và có thể tái sử dụng.

---

# Mục tiêu bài thực hành

Triển khai các thành phần hạ tầng AWS sau:

- VPC
- Public Subnet
- Private Subnet
- Internet Gateway
- NAT Gateway
- Route Tables
- Public EC2 Instance
- Private EC2 Instance
- Security Groups

Ngoài ra:
- Tổ chức Terraform theo dạng Modules
- Viết CloudFormation Template tương đương
- Quản lý source code bằng GitHub

---

# Công nghệ sử dụng

| Công nghệ | Mục đích |
|---|---|
| AWS | Cloud Platform |
| Terraform | Infrastructure as Code |
| CloudFormation | Native IaC của AWS |
| AWS CLI | Quản lý AWS qua command line |
| GitHub | Quản lý source code |

---

# Kiến trúc hệ thống

Hệ thống bao gồm:

- Một VPC riêng
- Một Public Subnet
- Một Private Subnet
- EC2 Public có thể truy cập Internet
- EC2 Private chỉ truy cập Internet thông qua NAT Gateway
- Security Group kiểm soát traffic

---

# Cấu trúc thư mục

```bash
.
├── terraform/
│   ├── modules/
│   │   ├── network/
│   │   ├── security/
│   │   └── ec2/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── provider.tf
│
├── cloudformation/
│   └── infrastructure.yaml
│
├── docs/
│
└── README.md
```

---

# Yêu cầu trước khi cài đặt

Trước khi chạy dự án cần chuẩn bị:

- AWS Account
- IAM User có quyền EC2, VPC
- AWS CLI
- Terraform
- Git
- SSH Key Pair

---

# Cách setup môi trường

## 1. Clone source code

```bash
git clone <https://github.com/Lucas-1712/nt548-lab01.git>
cd nt548-lab01
```

---

## 2. Cài đặt Terraform

### Ubuntu/Linux

```bash
sudo snap install terraform --classic
```

### Windows

Tải Terraform tại:

https://developer.hashicorp.com/terraform/downloads

Kiểm tra:

```bash
terraform -version
```

---

## 3. Cài đặt AWS CLI

### Ubuntu/Linux

```bash
sudo apt install awscli -y
```

### Windows

Tải AWS CLI tại:

https://aws.amazon.com/cli/

Kiểm tra:

```bash
aws --version
```

---

## 4. Cấu hình AWS CLI

Chạy lệnh:

```bash
aws configure
```

Nhập:

```bash
AWS Access Key ID
AWS Secret Access Key
Default region name
Default output format
```

Ví dụ:

```bash
AWS Access Key ID: ****************
AWS Secret Access Key: ****************
Default region name: ap-southeast-1
Default output format: json
```

---

## 5. Tạo SSH Key Pair

```bash
ssh-keygen -t rsa -b 4096
```

Hoặc tạo trực tiếp trên AWS EC2 Console.

---

# Terraform Modules

## 1. Network Module
Quản lý:
- VPC
- Subnets
- Internet Gateway
- NAT Gateway
- Route Tables

## 2. Security Module
Quản lý:
- Security Groups
- Inbound/Outbound Rules

## 3. EC2 Module
Triển khai:
- Public EC2 Instance
- Private EC2 Instance

---

# Các bước triển khai Terraform

## 1. Di chuyển vào thư mục Terraform

```bash
cd terraform
```

---

## 2. Khởi tạo Terraform

```bash
terraform init
```

Lệnh này sẽ:
- Tải provider AWS
- Khởi tạo Terraform working directory

---

## 3. Kiểm tra kế hoạch triển khai

```bash
terraform plan
```

Terraform sẽ hiển thị:
- Tài nguyên sẽ được tạo
- Tài nguyên sẽ thay đổi
- Tài nguyên sẽ bị xóa

---

## 4. Triển khai hạ tầng

```bash
terraform apply
```

Nhập:

```bash
yes
```

Sau khi hoàn thành:
- AWS VPC được tạo
- EC2 được tạo
- Security Groups được áp dụng

---

## 5. Kiểm tra tài nguyên trên AWS

Vào:
- VPC Dashboard
- EC2 Dashboard
- Route Tables
- NAT Gateway

Để xác nhận hạ tầng đã được triển khai thành công.

---

## 6. SSH vào Public EC2

```bash
ssh -i <keypair>.pem ec2-user@<public-ip>
```

Ví dụ:

```bash
ssh -i nt548-key.pem ec2-user@54.xxx.xxx.xxx
```

---

# CloudFormation

Thư mục `cloudformation/` chứa template triển khai hạ tầng AWS bằng AWS CloudFormation.

---

# Triển khai CloudFormation

## 1. Di chuyển vào thư mục

```bash
cd cloudformation
```

---

## 2. Tạo Stack

```bash
aws cloudformation create-stack \
  --stack-name nt548-lab01 \
  --template-body file://infrastructure.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## 3. Kiểm tra trạng thái Stack

```bash
aws cloudformation describe-stacks \
  --stack-name nt548-lab01
```

---

# Xóa hạ tầng

## Terraform

```bash
terraform destroy
```

## CloudFormation

```bash
aws cloudformation delete-stack \
  --stack-name nt548-lab01
```

---

# Kết quả đạt được

Sau khi triển khai thành công:

- Tạo được VPC riêng
- Public EC2 truy cập Internet thành công
- Private EC2 truy cập Internet thông qua NAT Gateway
- Security Group hoạt động đúng
- Terraform Modules hoạt động độc lập
- CloudFormation triển khai được hạ tầng tương tự

---

# Kiến thức đạt được

Thông qua bài lab này:
- Hiểu Infrastructure as Code
- Sử dụng Terraform Modules
- Làm việc với AWS Networking
- Triển khai EC2 tự động
- Quản lý hạ tầng bằng CloudFormation
- Sử dụng AWS CLI và GitHub trong DevOps workflow

---

# Thành viên thực hiện
- Nhóm 17:
- Vũ Lê Phát Tài
- Sít Khải Đông
- Nguyễn Gia Bảo
- Võ Minh An

---

# Tài liệu tham khảo

- Terraform Documentation
- AWS Documentation
- CloudFormation Documentation
- AWS CLI Documentation
