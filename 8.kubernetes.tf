resource "aws_vpc" "sai01_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "sai01-vpc"
  }
}

resource "aws_subnet" "sai01_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.sai01_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.sai01_vpc.cidr_block, 8, count.index)
  availability_zone       = element(["ap-south-1a", "ap-south-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "sai01-subnet-${count.index}"
    "kubernetes.io/cluster/sai011-cluster" = "shared"
    "kubernetes.io/role/elb"                  = "1"
  }
}

resource "aws_internet_gateway" "sai01_igw" {
  vpc_id = aws_vpc.sai01_vpc.id

  tags = {
    Name = "sai01-igw"
  }
}

resource "aws_route_table" "sai01_route_table" {
  vpc_id = aws_vpc.sai01_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sai01_igw.id
  }
   route {
    cidr_block                = "10.5.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  }

  tags = {
    Name = "sai01-route-table"
  }
}

resource "aws_route_table_association" "sai01_association" {
  count          = 2
  subnet_id      = aws_subnet.sai01_subnet[count.index].id
  route_table_id = aws_route_table.sai01_route_table.id
}

resource "aws_security_group" "sai01_cluster_sg" {
  name   = "sai01-cluster-sg"
  vpc_id = aws_vpc.sai01_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sai01-cluster-sg"
  }
}

resource "aws_security_group" "sai01_node_sg" {
  name   = "sai01-node-sg"
  vpc_id = aws_vpc.sai01_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sai01-node-sg"
  }
}

resource "aws_eks_cluster" "sai01" {
  name     = "sai011-cluster"
  role_arn = aws_iam_role.sai01_cluster_role.arn

  vpc_config {
    subnet_ids              = aws_subnet.sai01_subnet[*].id
    endpoint_public_access  = true
    endpoint_private_access = false
    security_group_ids      = [aws_security_group.sai01_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.sai01_cluster_role_policy
  ]
}

resource "aws_eks_node_group" "sai01" {
  cluster_name    = aws_eks_cluster.sai01.name
  node_group_name = "sai01-node-group"
  node_role_arn   = aws_iam_role.sai01_node_group_role.arn
  subnet_ids      = aws_subnet.sai01_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["m7i-flex.large"]

  remote_access {
    ec2_ssh_key               = var.ec2_key
    source_security_group_ids = [aws_security_group.sai01_node_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.sai01_node_group_role_policy,
    aws_iam_role_policy_attachment.sai01_node_group_cni_policy,
    aws_iam_role_policy_attachment.sai01_node_group_registry_policy,
    aws_iam_role_policy_attachment.sai01_node_group_ebs_policy
  ]
}


# For 1st time without roles
resource "aws_iam_role" "sai01_cluster_role" {
  name = "sai01-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sai01_cluster_role_policy" {
  role       = aws_iam_role.sai01_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "sai01_node_group_role" {
  name = "sai01-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sai01_node_group_role_policy" {
  role       = aws_iam_role.sai01_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "sai01_node_group_cni_policy" {
  role       = aws_iam_role.sai01_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "sai01_node_group_registry_policy" {
  role       = aws_iam_role.sai01_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "sai01_node_group_ebs_policy" {
  role       = aws_iam_role.sai01_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}



resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.sai01.name
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.58.0-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  service_account_role_arn = aws_iam_role.ebs_csi.arn 
  depends_on = [ aws_iam_openid_connect_provider.eks ]
}


data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.sai01.name
}

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_role" "ebs_csi" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_policy" "saieks_addon_policy" {
  name = "saiEKSAddonFullAccess"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeAddon",
        "eks:CreateAddon",
        "eks:DeleteAddon",
        "eks:UpdateAddon",
        "eks:ListAddons"
      ]
      Resource = "*"
    }]
  })
}

variable "ec2_key" {
  description = "The name of the SSH key pair to use for instances"
  type        = string
  default     = "ec2-key"
}


# For send time and later use this block 
/* 
# =========================
# EXISTING IAM ROLE ARNs
# =========================

locals {
  cluster_role_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:role/sai01-cluster-role"
  node_role_arn    = "arn:aws:iam::YOUR_ACCOUNT_ID:role/sai01-node-group-role"
  ebs_csi_role_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole"
}

*/