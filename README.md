# NT548 - Bài tập thực hành 01

## Đề tài

Dùng Terraform và CloudFormation để quản lý và triển khai hạ tầng AWS.

## Mục tiêu

Bài thực hành triển khai hạ tầng AWS tự động bằng Infrastructure as Code.

Các thành phần chính:

- VPC
- Public Subnet
- Private Subnet
- Internet Gateway
- NAT Gateway
- Public Route Table
- Private Route Table
- Public EC2 Instance
- Private EC2 Instance
- Security Group
- Terraform Modules
- CloudFormation Template

## Công nghệ sử dụng

- AWS
- Terraform
- CloudFormation
- AWS CLI
- GitHub

## Cấu trúc thư mục

```text
.
├── terraform/
│   ├── modules/
│   │   ├── network/
│   │   ├── security/
│   │   └── ec2/
│   └── ...
├── cloudformation/
├── docs/
└── README.md
