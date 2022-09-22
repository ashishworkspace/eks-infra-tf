variable "region" {
    default = "ap-south-1"
}
# variable "prefix" {}
variable "environment" {
    default = "dev"
}
variable "eks_kubernetes_version" {
    default = "1.23"
}
variable "vpc_id" {
    default = "vpc-070f696830bda1baa"
}
# variable "vpc_security_group_ids" {
#     # default = ""
# }
variable "subnets" {
    type = list(string)
    default = [ "subnet-0dcbaeaacaa07f052", "subnet-0ff42f18886e1a7e7" ]
}
variable "eks_managed_instance_min_size" {
    default = "1"
}
variable "eks_managed_instance_max_size" {
    default = "10"
}
variable "eks_managed_instance_desired_size" {
    default = "4"
}
variable "eks_managed_instance_types" {
    default = ["t3a.medium"]
}


variable "eks_managed_instance_min_size_prod" {
    default = "1"
}
variable "eks_managed_instance_max_size_prod" {
    default = "20"
}
variable "eks_managed_instance_desired_size_prod" {
    default = "1"
}
variable "eks_managed_instance_types_prod" {
    default = ["t3a.2xlarge"]
}



variable "eks_managed_instance_min_size_prod2" {
    default = "1"
}
variable "eks_managed_instance_max_size_prod2" {
    default = "20"
}
variable "eks_managed_instance_desired_size_prod2" {
    default = "3"
}
variable "eks_managed_instance_types_prod2" {
    default = ["t3a.medium"]
}

variable "eks_managed_instance_min_size_prod3" {
    default = "3"
}
variable "eks_managed_instance_max_size_prod3" {
    default = "30"
}
variable "eks_managed_instance_desired_size_prod3" {
    default = "16"
}
variable "eks_managed_instance_types_prod3" {
    default = ["t3a.medium"]
}



variable "eks_managed_instance_min_size_prod4" {
    default = "1"
}
variable "eks_managed_instance_max_size_prod4" {
    default = "20"
}
variable "eks_managed_instance_desired_size_prod4" {
    default = "2"
}
variable "eks_managed_instance_types_prod4" {
    default = ["t3a.xlarge"]
}
# variable "eks_managed_capacity_type" {}

variable "nginx_ingress_node_desired-0" {
    default = "1"
}
variable "nginx_ingress_node_min-0" {
    default = "1"
}
variable "nginx_ingress_node_max-0" {
    default = "3"
}
variable "nginx_ingress_instance_type-0" {
    default = ["t3a.medium"]
}