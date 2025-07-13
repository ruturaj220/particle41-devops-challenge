# Resource: AWS VPC
# Creates a new Virtual Private Cloud (VPC) in AWS.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block # Uses the VPC CIDR block from variables.
  enable_dns_support   = true               # Enables DNS resolution for instances in the VPC.
  enable_dns_hostnames = true               # Enables DNS hostnames for instances in the VPC.

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = "dev"
  }
}

# Resource: AWS Internet Gateway
# Creates an Internet Gateway to allow communication between the VPC and the internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # Attaches the IGW to our main VPC.

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = "dev"
  }
}

# Resource: AWS Public Subnets
# Creates public subnets within the VPC. These subnets are associated with the IGW.
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidr_blocks) # Creates one subnet for each CIDR block defined in the variable.
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  # Assigns each public subnet to a different Availability Zone (AZ) for high availability.
  availability_zone = data.aws_availability_zones.available.names[count.index]
  # Automatically assigns a public IP address to instances launched in this subnet.
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet-${count.index + 1}"
    Environment = "dev"
  }
}

# Resource: AWS Private Subnets
# Creates private subnets within the VPC. These subnets are not directly accessible from the internet.
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr_blocks) # Creates one subnet for each CIDR block defined in the variable.
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  # Assigns each private subnet to a different Availability Zone (AZ) for high availability.
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-private-subnet-${count.index + 1}"
    Environment = "dev"
  }
}

# Data Source: AWS Availability Zones
# Retrieves a list of available Availability Zones in the specified region.
data "aws_availability_zones" "available" {
  state = "available"
}

# Resource: AWS EIP (Elastic IP for NAT Gateway)
# Allocates a static public IP address for the NAT Gateway.
resource "aws_eip" "nat_gateway_eip" {
  # We only need one NAT Gateway for this setup, so count is 1.
  # For higher availability in production, you might create one NAT Gateway per public subnet.
  count = 1 
  tags = {
    Name        = "${var.project_name}-nat-gateway-eip-${count.index + 1}"
    Environment = "dev"
  }
}

# Resource: AWS NAT Gateway
# Creates a NAT Gateway in a public subnet to allow instances in private subnets to access the internet.
resource "aws_nat_gateway" "main" {
  # We only need one NAT Gateway for this setup, so count is 1.
  count         = 1
  allocation_id = aws_eip.nat_gateway_eip[count.index].id # Associates the EIP with the NAT Gateway.
  # Places the NAT Gateway in the first public subnet.
  subnet_id     = aws_subnet.public[0].id 

  tags = {
    Name        = "${var.project_name}-nat-gateway-${count.index + 1}"
    Environment = "dev"
  }
  # Ensures the NAT Gateway is created after the EIP is allocated.
  depends_on = [aws_internet_gateway.main]
}

# Resource: AWS Route Table (Public)
# Creates a route table for public subnets, directing internet-bound traffic to the Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"        # Default route for all internet-bound traffic.
    gateway_id = aws_internet_gateway.main.id # Directs traffic to the Internet Gateway.
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = "dev"
  }
}

# Resource: AWS Route Table (Private)
# Creates a route table for private subnets, directing internet-bound traffic to the NAT Gateway.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"        # Default route for all internet-bound traffic.
    nat_gateway_id = aws_nat_gateway.main[0].id # Directs traffic to the NAT Gateway.
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = "dev"
  }
}

# Resource: AWS Route Table Association (Public Subnets)
# Associates each public subnet with the public route table.
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Resource: AWS Route Table Association (Private Subnets)
# Associates each private subnet with the private route table.
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
