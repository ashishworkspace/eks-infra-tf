# Terraform Remote State Datasource - Remote Backend AWS S3
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "eks-tf-dev"
    key    = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}
