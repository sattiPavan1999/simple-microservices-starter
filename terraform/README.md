# Terraform – simple-microservices-starter (AWS)

Creates a VPC, two RDS PostgreSQL databases (one per backend: `users_db`, `products_db`) and an EKS cluster whose worker nodes run only in the private subnets.

## Layout

```
Internet
   |
[ALB SG]  public subnets (x2 AZ)  -> IGW, NAT gateway
   |
[frontend SG :3000] [users SG :3001] [products SG :3002]   private subnets (x2 AZ) -> NAT
   |                      |
   |                [users-rds SG]   [products-rds SG]     db subnets (x2 AZ), no internet route
```

## Usage

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
aws configure            # or export AWS_PROFILE=...
terraform init
terraform plan
terraform apply
```

Get the DB connection strings (stored as encrypted SSM parameters):

```bash
aws ssm get-parameter --name /simple-microservices-dev/users/DATABASE_URL \
  --with-decryption --query Parameter.Value --output text
```

## Connect to EKS

```bash
aws eks update-kubeconfig --region ap-south-1 --name simple-microservices-dev-eks
kubectl get nodes
```

## Clean up (important, NAT + RDS cost money)

```bash
terraform destroy
```
