locals {
  vpc = {
    azs        = slice(data.aws_availability_zones.available.names, 0, var.az_num)
    cidr_block = var.vpc_cidr_block
  }

  rds = {
    engine         = "mysql"
    engine_version = "8.0.35"
    instance_class = "db.t3.micro"
    db_name        = "mydb"
    username       = "dbuser123"
  }

  vm = {
    instance_type = "m5.large"
    instance_requirements = {
      memory_mib = {
        min = 8192
      }
      vcpu_count = {
        min = 2
      }
      instance_generations = ["current"]
    }
  }

  demo = {
    admin = {
      username = "wpadmin"
      password = "wppassword"
      email    = "admin@demo.com"
    }
  }
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "linux" {
  owners      = ["amazon"]
  most_recent = true
  name_regex  = "^al2023-ami-2023\\..*"
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_iam_policy" "administrator" {
  name = "AdministratorAccess"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_vpc" "default" {
  cidr_block           = local.vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.namespace}-vpc"
  }
}

resource "aws_subnet" "public" {
  for_each = { for index, az_name in local.vpc.azs : index => az_name }
  vpc_id                  = aws_vpc.default.id
  cidr_block              = cidrsubnet(aws_vpc.default.cidr_block, 8, each.key)
  availability_zone       = each.value
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.namespace}-subnet-public-${each.key}"
  }
}

resource "aws_security_group" "nfs" {
  name_prefix = "${var.namespace}-nfs-"
  vpc_id      = aws_vpc.default.id
  ingress {
    description = "Allow any NFS traffic from private subnets"
    cidr_blocks = concat(values(aws_subnet.private)[*].cidr_block, values(aws_subnet.private_ingress)[*].cidr_block)
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }
  egress {
    description      = "Allow all outbound traffic"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(["ssm", "ssmmessages", "ec2messages", "secretsmanager"])
  vpc_id              = aws_vpc.default.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids         = values(aws_subnet.private_ingress)[*].id
  security_group_ids = [aws_security_group.any.id]
  tags = {
    Name = "${var.namespace}-endpoint-${each.key}"
  }
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(["s3"])
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  tags = {
    Name = "${var.namespace}-endpoint-${each.key}"
  }
}
