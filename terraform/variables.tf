variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1" # Mumbai
}

variable "project_name" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "simple-microservices"
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
  default     = "dev"
}

# ---------- Networking ----------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to use (RDS subnet groups need at least 2)"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Create a single NAT gateway so private subnets can reach the internet (costs ~$32/month + data). Set false to save money."
  type        = bool
  default     = true
}

# ---------- Application services ----------
variable "frontend_port" {
  description = "Port the frontend container listens on"
  type        = number
  default     = 3000
}

variable "backend_services" {
  description = "Backend services. Each gets its own security group and its own RDS PostgreSQL instance."
  type = map(object({
    port    = number
    db_name = string
  }))
  default = {
    users = {
      port    = 3001
      db_name = "users_db"
    }
    products = {
      port    = 3002
      db_name = "products_db"
    }
  }
}

# ---------- RDS ----------
variable "db_engine_major_version" {
  description = "PostgreSQL major version (docker-compose uses 16)"
  type        = string
  default     = "16"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.m7.large" # RDS instance class for backend services
}

variable "db_allocated_storage" {
  description = "Storage in GB for each RDS instance"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Master username for the databases"
  type        = string
  default     = "dbadmin"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ (doubles cost; not needed for practice)"
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Automated backup retention. Use 0 to disable (some free-plan accounts require 0 or 1)."
  type        = number
  default     = 1
}

variable "db_force_ssl" {
  description = "Require SSL for DB connections. PostgreSQL 15+ on RDS enforces SSL by default, but the starter apps connect without SSL, so it is off for practice. Turn on in real environments and configure SSL in the apps."
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Protect DB from accidental deletion. Keep false so `terraform destroy` works while practicing."
  type        = bool
  default     = false
}

# ---------- EKS ----------
variable "eks_kubernetes_version" {
  description = "Kubernetes version. null = latest version supported by EKS. (Old versions fall into paid 'extended support', so check the supported list before pinning.)"
  type        = string
  default     = null
}

variable "eks_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint (kubectl from your laptop). Restrict to your IP, e.g. [\"203.0.113.10/32\"]."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_node_instance_types" {
  description = "Instance types for the managed node group"
  type        = list(string)
  default     = ["t2.large"]
}

variable "eks_node_desired_size" {
  type    = number
  default = 2
}

variable "eks_node_min_size" {
  type    = number
  default = 1
}

variable "eks_node_max_size" {
  type    = number
  default = 3
}

variable "eks_node_disk_size" {
  description = "Node root volume size in GB"
  type        = number
  default     = 20
}
