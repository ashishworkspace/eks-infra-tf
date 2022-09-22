locals {
  tags = {
    managed-by  = "terraform"
    environment = var.environment
  }
}

resource "aws_iam_role" "eks-cluster-role" {
  name = "eks-cluster-role-0"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com",
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role.name
}
# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks-cluster-role.name
}

resource "aws_iam_role" "eks-node-role" {
  name = "eks-node-role-0"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com",
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-node-role.name
}
resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node-role.name
}
resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node-role.name
}
resource "aws_iam_role_policy_attachment" "node-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks-node-role.name
}

resource "aws_eks_cluster" "eks01" {
  name     = "${var.environment}-eks01"
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    subnet_ids = var.subnets
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController
  ]
}

resource "aws_launch_template" "ekslaunchtemplate" {
  name = "eks-managed-launchtemplate-0"
  # vpc_security_group_ids = concat(var.vpc_security_group_ids, [aws_eks_cluster.eks01.vpc_config[0].cluster_security_group_id])
  tags = local.tags
}

resource "aws_eks_node_group" "eksng01" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "eks-managed-0"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnets

  launch_template {
    id      = aws_launch_template.ekslaunchtemplate.id
    version = aws_launch_template.ekslaunchtemplate.latest_version
  }

  scaling_config {
    desired_size = var.eks_managed_instance_desired_size
    min_size     = var.eks_managed_instance_min_size
    max_size     = var.eks_managed_instance_max_size
  }
  labels = {
    "app"  = "cherry"
    "test" = "user_doc"
  }
  update_config {
    max_unavailable = 1
  }

  instance_types = var.eks_managed_instance_types
  # capacity_type  = var.eks_managed_capacity_type

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "shared"
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
  }
}
resource "aws_eks_node_group" "eksng02" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "eks-managed-1"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnets

  launch_template {
    id      = aws_launch_template.ekslaunchtemplate.id
    version = aws_launch_template.ekslaunchtemplate.latest_version
  }

  scaling_config {
    desired_size = var.eks_managed_instance_desired_size_prod
    min_size     = var.eks_managed_instance_min_size_prod
    max_size     = var.eks_managed_instance_max_size_prod
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.eks_managed_instance_types_prod
  # capacity_type  = var.eks_managed_capacity_type

  labels = {
    "purpose" = "flask-app"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "shared"
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
  }
}


resource "aws_eks_node_group" "eksng03" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "eks-managed-2"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnets

  launch_template {
    id      = aws_launch_template.ekslaunchtemplate.id
    version = aws_launch_template.ekslaunchtemplate.latest_version

  }
  labels = {
    "groupRole" = "master",
    "purpose"   = "redis",
  }
  scaling_config {
    desired_size = var.eks_managed_instance_desired_size_prod2
    min_size     = var.eks_managed_instance_min_size_prod2
    max_size     = var.eks_managed_instance_max_size_prod2
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.eks_managed_instance_types_prod2

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "shared"
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
  }
}


resource "aws_eks_node_group" "eksng04" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "eks-managed-3"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnets

  launch_template {
    id      = aws_launch_template.ekslaunchtemplate.id
    version = aws_launch_template.ekslaunchtemplate.latest_version

  }
  labels = {
    groupRole   = "worker",
    instanceEnv = "prod"
  }
  scaling_config {
    desired_size = var.eks_managed_instance_desired_size_prod3
    min_size     = var.eks_managed_instance_min_size_prod3
    max_size     = var.eks_managed_instance_max_size_prod3
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.eks_managed_instance_types_prod3

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "shared"
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
  }
}

resource "aws_eks_node_group" "eksng05" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "eks-managed-4"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnets

  launch_template {
    id      = aws_launch_template.ekslaunchtemplate.id
    version = aws_launch_template.ekslaunchtemplate.latest_version

  }
  labels = {
    "instanceEnv" = "prod-dag"
    "purpose"     = "superset"
  }
  scaling_config {
    desired_size = var.eks_managed_instance_desired_size_prod4
    min_size     = var.eks_managed_instance_min_size_prod4
    max_size     = var.eks_managed_instance_max_size_prod4
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.eks_managed_instance_types_prod4

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "shared"
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
  }
}
# resource "aws_eks_node_group" "nginx-ingress" {
#   cluster_name    = aws_eks_cluster.eks01.name
#   node_group_name = "nginx-ingress-controller"
#   node_role_arn   = aws_iam_role.eks-node-role.arn
#   subnet_ids      = var.subnets

#   launch_template {
#     id      = aws_launch_template.ekslaunchtemplate.id
#     version = aws_launch_template.ekslaunchtemplate.latest_version

#   }
#   labels = {
#     "app" = "nginx-ingress-controller"
#   }
#   scaling_config {
#     desired_size = var.nginx_ingress_node_desired
#     min_size     = var.nginx_ingress_node_min
#     max_size     = var.nginx_ingress_node_min
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   instance_types = var.nginx_ingress_instance_type

#   depends_on = [
#     aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
#   ]
#   tags = {
#     "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "shared"
#     "k8s.io/cluster-autoscaler/enabled"                       = "true"
#   }
# }
resource "aws_eks_node_group" "nginx-ingress0" {
  cluster_name    = aws_eks_cluster.eks01.name
  node_group_name = "nginx-ingress-controller-0"
  node_role_arn   = aws_iam_role.eks-node-role.arn
  subnet_ids      = var.subnets

  launch_template {
    id      = aws_launch_template.ekslaunchtemplate.id
    version = aws_launch_template.ekslaunchtemplate.latest_version

  }
  labels = {
    "app" = "nginx-ingress-controller"
  }
  scaling_config {
    desired_size = var.nginx_ingress_node_desired-0
    min_size     = var.nginx_ingress_node_min-0
    max_size     = var.nginx_ingress_node_min-0
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = var.nginx_ingress_instance_type-0

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = {
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.eks01.name}" = "shared"
    "k8s.io/cluster-autoscaler/enabled"                       = "true"
  }
}

# Enable iam roles for service accounts via oidc provider
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
data "tls_certificate" "ekstlsc01" {
  url = aws_eks_cluster.eks01.identity[0].oidc[0].issuer
}
resource "aws_iam_openid_connect_provider" "eksoidcprovider" {
  url             = aws_eks_cluster.eks01.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ekstlsc01.certificates[0].sha1_fingerprint]
}

output "aws_iam_openid_connect_provider_arn" {
  description = "AWS IAM Open ID Connect Provider ARN"
  value       = aws_iam_openid_connect_provider.eksoidcprovider.arn
}

# Extract OIDC Provider from OIDC Provider ARN
locals {
  aws_iam_oidc_connect_provider_extract_from_arn = element(split("oidc-provider/", "${aws_iam_openid_connect_provider.eksoidcprovider.arn}"), 1)
}

# Output: AWS IAM Open ID Connect Provider
output "aws_iam_openid_connect_provider_extract_from_arn" {
  description = "AWS IAM Open ID Connect Provider extract from ARN"
  value       = local.aws_iam_oidc_connect_provider_extract_from_arn
}



resource "aws_iam_role" "eksiamrole" {
  name = "eks-iam-role-0"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Principal = {
        Federated = [aws_iam_openid_connect_provider.eksoidcprovider.arn]
      }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:sub" = ["system:serviceaccount:kube-system:aws-node"]
        }
      }
      Action = ["sts:AssumeRoleWithWebIdentity"]
    }
  })
}

# Create eks secrets manager role
# Reference: https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html
resource "aws_iam_role" "ekssecretsmanagerrole" {
  name = "eks-secrets-manager-role-0"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eksoidcprovider.url}"
        },
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:aud" : "sts.amazonaws.com",
          }
        }
        Action = "sts:AssumeRoleWithWebIdentity"
      },
    ]
  })
}
resource "aws_iam_policy" "ekssecretsmanagerpolicy" {
  name = "eks-secretsmanager-policy-0"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:demo-*"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      },
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ekssecretsmanagerroleattachment" {
  role       = aws_iam_role.ekssecretsmanagerrole.name
  policy_arn = aws_iam_policy.ekssecretsmanagerpolicy.arn
}

# # Create eks iam load balancer role
# # Reference: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
# resource "aws_iam_role" "ekslbrole" {
#   name = "eks-load-balanacer-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${aws_iam_openid_connect_provider.eksoidcprovider.url}"
#         },
#         Condition = {
#           StringEquals = {
#             "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:aud" : "sts.amazonaws.com",
#           }
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#       },
#     ]
#   })
# }
# resource "aws_iam_policy" "albcontrollerpolicy" {
#   name   = "AWSLoadBalancerControllerIAMPolicy"
#   policy = file("${path.module}/awslbcontroller_policy.json")
# }
# resource "aws_iam_role_policy_attachment" "ekslbroleattachment01" {
#   role       = aws_iam_role.ekslbrole.name
#   policy_arn = aws_iam_policy.albcontrollerpolicy.arn
# }
# resource "aws_iam_role_policy_attachment" "ekslbroleattachment02" {
#   role       = aws_iam_role.ekslbrole.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
# }

data "aws_caller_identity" "current" {}




data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksoidcprovider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksoidcprovider.arn]
      type        = "Federated"
    }
  }
}
resource "aws_iam_role" "eks_cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role_policy.json
  name               = "eks-cluster-autoscaler-0"
}
resource "aws_iam_role_policy_attachment" "eksclusterautoscalerroleattachment01" {
  role       = aws_iam_role.eks_cluster_autoscaler.name
  policy_arn = aws_iam_policy.eksclusterautoscalerpolicy.arn
}

resource "aws_iam_policy" "eksclusterautoscalerpolicy" {
  name = "eks-cluster-autoscaler-0"

  policy = jsonencode({
    Statement = [{
      Action = [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "ec2:DescribeLaunchTemplateVersions"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

output "eks_cluster_autoscaler_arn" {
  value = aws_iam_role.eks_cluster_autoscaler.arn
}


# Provide the eks-cluster-autoscaler arn value inside  <cluster-autoscaler.yml>
