terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}


locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "vpc"
    }
  )

  public_subnets = {
    for index, cidr in var.public_subnet_cidrs :
    tostring(index) => {
      availability_zone = var.availability_zones[index]
      cidr_block        = cidr
    }
  }

  private_application_subnets = {
    for index, cidr in var.private_application_subnet_cidrs :
    tostring(index) => {
      availability_zone = var.availability_zones[index]
      cidr_block        = cidr
    }
  }

  isolated_database_subnets = {
    for index, cidr in var.isolated_database_subnet_cidrs :
    tostring(index) => {
      availability_zone = var.availability_zones[index]
      cidr_block        = cidr
    }
  }

  nat_gateway_count = var.enable_nat_gateway ? (
    var.single_nat_gateway ? 1 : length(var.availability_zones)
  ) : 0
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    precondition {
      condition = (
        length(var.public_subnet_cidrs) == length(var.availability_zones) &&
        length(var.private_application_subnet_cidrs) == length(var.availability_zones) &&
        length(var.isolated_database_subnet_cidrs) == length(var.availability_zones)
      )

      error_message = "Every subnet tier must contain exactly one CIDR block per Availability Zone."
    }
  }
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress = []
  egress  = []

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-default-deny-all"
    }
  )
}



resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-public-${each.value.availability_zone}"
      Tier = "public"
    }
  )
}

resource "aws_subnet" "private_application" {
  for_each = local.private_application_subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-private-app-${each.value.availability_zone}"
      Tier = "private-application"
    }
  )
}

resource "aws_subnet" "isolated_database" {
  for_each = local.isolated_database_subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-isolated-db-${each.value.availability_zone}"
      Tier = "isolated-database"
    }
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-public"
      Tier = "public"
    }
  )
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-${count.index + 1}"
    }
  )
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[tostring(count.index)].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private_application" {
  for_each = local.private_application_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-private-app-${each.value.availability_zone}"
      Tier = "private-application"
    }
  )
}

resource "aws_route" "private_nat" {
  for_each = var.enable_nat_gateway ? local.private_application_subnets : {}

  route_table_id         = aws_route_table.private_application[each.key].id
  destination_cidr_block = "0.0.0.0/0"

  nat_gateway_id = aws_nat_gateway.this[
    var.single_nat_gateway ? 0 : tonumber(each.key)
  ].id
}

resource "aws_route_table_association" "private_application" {
  for_each = aws_subnet.private_application

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_application[each.key].id
}

resource "aws_route_table" "isolated_database" {
  for_each = local.isolated_database_subnets

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-isolated-db-${each.value.availability_zone}"
      Tier = "isolated-database"
    }
  )
}

resource "aws_route_table_association" "isolated_database" {
  for_each = aws_subnet.isolated_database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.isolated_database[each.key].id
}