terraform {
  required_version = ">= 1.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.23"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.4.0" # due to bug: https://github.com/hashicorp/terraform-provider-tls/issues/244
    }
  }
  backend "s3" {
    bucket = "eks-tf-dev"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"

    # For State Locking
    # dynamodb_table = "prod-ekscluster"   
  }
}
