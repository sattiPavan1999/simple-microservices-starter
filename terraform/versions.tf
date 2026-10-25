terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
     source  = "hashicorp/aws"
     version = ">= 5.0, < 7.0"
   }
   random = {
     source  = "hashicorp/random"
     version = ">= 3.6"
   }
  }

  # For practice we keep state locally.
  # Later you can move to S3 + DynamoDB locking:
  # backend "s3" {
  #   bucket         = "your-tf-state-bucket"
  #   key            = "simple-microservices/dev/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "your-tf-lock-table"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
