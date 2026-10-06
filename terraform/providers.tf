terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project        = "lab1"
  ecr_repository = "lab1-api"
  ecs_cluster    = "lab1-cluster"
  ecs_service    = "lab1-api"
  container_name = "api"
  container_port = 8000
  db_name        = "lab1"
  db_username    = "lab1"

  tags = {
    Project   = "lab1"
    ManagedBy = "terraform"
  }
}
