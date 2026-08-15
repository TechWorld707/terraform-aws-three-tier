mock_provider "aws" {}

variables {
  name               = "test-platform-dev"
  vpc_cidr           = "10.10.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]

  public_subnet_cidrs = [
    "10.10.0.0/24",
    "10.10.1.0/24",
  ]

  private_application_subnet_cidrs = [
    "10.10.10.0/24",
    "10.10.11.0/24",
  ]

  isolated_database_subnet_cidrs = [
    "10.10.20.0/24",
    "10.10.21.0/24",
  ]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_flow_logs   = false

  tags = {
    Environment = "test"
  }
}

run "development_network_plan" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 2
    error_message = "The module must create two public subnets."
  }

  assert {
    condition     = length(aws_subnet.private_application) == 2
    error_message = "The module must create two private application subnets."
  }

  assert {
    condition     = length(aws_subnet.isolated_database) == 2
    error_message = "The module must create two isolated database subnets."
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "Development must use one shared NAT gateway."
  }

  assert {
    condition     = length(aws_eip.nat) == 1
    error_message = "One Elastic IP must be created for the shared NAT gateway."
  }

  assert {
    condition     = length(aws_route_table.isolated_database) == 2
    error_message = "Each isolated database subnet must have an isolated route table."
  }

  assert {
    condition     = aws_route.public_internet.destination_cidr_block == "0.0.0.0/0"
    error_message = "The public route table must provide an internet route."
  }

  assert {
    condition     = aws_subnet.public["0"].map_public_ip_on_launch == false
    error_message = "Public subnets must not automatically assign public IP addresses."
  }
}