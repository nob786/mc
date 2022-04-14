terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.0.2"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }

    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = "0.2.1"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA4QGSY7HUJXPARXWQ"
  secret_key = "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"
  #   profile = "nofel"
}

resource "aws_vpc" "mcStagingVpc" {
  cidr_block = "192.168.0.0/16"
  tags = {
    "Name" = "MC Staging VPC"
  }
}

resource "aws_subnet" "PublicSubnet01Block" {
  vpc_id            = aws_vpc.mcStagingVpc.id
  cidr_block        = "192.168.0.0/18"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                   = "MC Staging Public Subnet"
    "PublicSubnet01"         = "PublicSubnet01Block"
    "Kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "PublicSubnet02Block" {
  vpc_id            = aws_vpc.mcStagingVpc.id
  cidr_block        = "192.168.64.0/18"
  availability_zone = "us-east-1a"

  tags = {
    "Name"                   = "MC Staging Public Subnet"
    "PublicSubnet01"         = "PublicSubnet02Block"
    "Kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "PrivateSubnet03Block" {
  vpc_id            = aws_vpc.mcStagingVpc.id
  cidr_block        = "192.168.128.0/18"
  availability_zone = "us-east-1b"

  tags = {
    "Name"                   = "MC Staging Private Subnet"
    "PrivateSubnet01"        = "PrivateSubnet03Block"
    "Kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "PrivateSubnet04Block" {
  vpc_id            = aws_vpc.mcStagingVpc.id
  cidr_block        = "192.168.192.0/18"
  availability_zone = "us-east-1c"

  tags = {
    "Name"                   = "MC Staging Private Subnet"
    "PrivateSubnet01"        = "PrivateSubnet03Block"
    "Kubernetes.io/role/elb" = "1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.mcStagingVpc.id

  tags = {
    Name = "MC Staging Internet Gateway"
  }
}

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.mcStagingVpc.id

  tags = {
    "Name"    = "MC Staging Public Route Table"
    "Network" = "Public"
  }
}

resource "aws_route_table" "PrivateRouteTable01" {
  vpc_id = aws_vpc.mcStagingVpc.id

  tags = {
    "Name"    = "MC Staging Private Route Table"
    "Network" = "Private"
  }
}

resource "aws_route_table" "PrivateRouteTable02" {
  vpc_id = aws_vpc.mcStagingVpc.id

  tags = {
    "Name"    = "MC Staging Private Route Table"
    "Network" = "Private"
  }
}

resource "aws_eip" "NatGatewayEIP1" {
  vpc = true
  tags = {
    Name = "Staging NAT IP 1"
  }
}
resource "aws_eip" "NatGatewayEIP2" {
  vpc = true
  tags = {
    Name = "Staging NAT IP 2"
  }
}

resource "aws_nat_gateway" "NatGateway01" {
  allocation_id = aws_eip.NatGatewayEIP1.id
  subnet_id     = aws_subnet.PublicSubnet01Block.id
  tags = {
    Name = "Staging NAT Gateway 1"
  }
}
resource "aws_nat_gateway" "NatGateway02" {
  allocation_id = aws_eip.NatGatewayEIP2.id
  subnet_id     = aws_subnet.PublicSubnet02Block.id
  tags = {
    Name = "Staging NAT Gateway 1"
  }
}

resource "aws_route" "PublicRoute" {
  route_table_id         = aws_route_table.PublicRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.InternetGateway.id
}
resource "aws_route" "PrivateRoute01" {
  route_table_id         = aws_route_table.PrivateRouteTable01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NatGateway01.id
}
resource "aws_route" "PrivateRoute02" {
  route_table_id         = aws_route_table.PrivateRouteTable02.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NatGateway02.id
}

resource "aws_route_table_association" "PublicSubnet01RouteTableAssociation" {
  subnet_id      = aws_subnet.PublicSubnet01Block.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "PublicSubnet02RouteTableAssociation" {
  subnet_id      = aws_subnet.PublicSubnet02Block.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "PrivateSubnet01RouteTableAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet03Block.id
  route_table_id = aws_route_table.PrivateRouteTable01.id
}

resource "aws_route_table_association" "PrivateSubnet02RouteTableAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet04Block.id
  route_table_id = aws_route_table.PrivateRouteTable02.id
}

resource "aws_security_group" "ControlPlaneSecurityGroup" {
  name        = "ControlPlaneSecurityGroup"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.mcStagingVpc.id
  tags = {
    Name = "MC Staging Security Group"
  }
}

# iam role for cluster
resource "aws_iam_role" "clusterRole" {
  name = "clusterSa"

  assume_role_policy = <<POLICY
{
"Version": "2012-10-17",
"Statement": [
    {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
    }
]
}
  POLICY
}

resource "aws_iam_role_policy_attachment" "clusterroleAmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.clusterRole.name
}

resource "aws_iam_role_policy_attachment" "clusterroleAmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.clusterRole.name
}

resource "aws_eks_cluster" "mc_staging" {
  name     = "mc_staging"
  role_arn = aws_iam_role.clusterRole.arn

  vpc_config {
    endpoint_private_access = true
    subnet_ids              = [aws_subnet.PublicSubnet01Block.id, aws_subnet.PublicSubnet02Block.id, aws_subnet.PrivateSubnet03Block.id, aws_subnet.PrivateSubnet04Block.id]
    #  security_group_ids = [aws_security_group.ControlPlaneSecurityGroup.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.clusterroleAmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.clusterroleAmazonEKSVPCResourceController,
  ]
}

resource "aws_iam_role" "mcStagingNoderole" {
  name = "eksNodeGroupStaging"


  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "stagingAmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.mcStagingNoderole.name
}

resource "aws_iam_role_policy_attachment" "stagingAmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.mcStagingNoderole.name
}

resource "aws_iam_role_policy_attachment" "stagingAmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.mcStagingNoderole.name
}

resource "aws_eks_node_group" "stagingNodeGgroup" {
  cluster_name    = aws_eks_cluster.mc_staging.name
  node_group_name = "stagingnodegroup"
  node_role_arn   = aws_iam_role.mcStagingNoderole.arn
  subnet_ids      = [aws_subnet.PrivateSubnet03Block.id, aws_subnet.PrivateSubnet04Block.id]
  instance_types = [ "t2.micro" ]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.stagingAmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.stagingAmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.stagingAmazonEC2ContainerRegistryReadOnly,
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

provider "kubernetes" {
  host                   = aws_eks_cluster.mc_staging.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.mc_staging.certificate_authority[0].data)
  token                  = aws_eks_cluster.mc_staging.token
  # load_config_file       = false
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.mc_staging.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.mc_staging.certificate_authority[0].data)
    token                  = aws_eks_cluster_auth.mc_staging.token
    load_config_file       = false
  }
}