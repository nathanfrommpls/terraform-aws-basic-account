# VPC

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = merge(var.tags, { Name = "Primary VPC" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = "Primary Internet Gateway" })
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = var.number_of_az
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % 2]

  depends_on = [aws_internet_gateway.igw]

  tags = merge(var.tags, { Name = "Public Subnet ${count.index}" })
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = "Public Route Table" })
}

resource "aws_route" "public_egress" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "basic_account_public" {
  count          = length(aws_subnet.public.*.id)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = var.number_of_az
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.${count.index + length(aws_subnet.public.*.id)}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % 2]

  tags = merge(var.tags, { Name = "Private Subnet ${count.index}" })
}

resource "aws_eip" "eip" {
  count = var.number_of_az
  tags  = merge(var.tags, { Name = "Elastic IP ${count.index}" })
}

resource "aws_nat_gateway" "ngw" {
  count         = var.number_of_az
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "NAT Gateway ${count.index}" })
}

resource "aws_route_table" "private_route_table" {
  count  = length(aws_subnet.private.*.id)
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, { Name = "Private Route Table ${count.index}" })
}

resource "aws_route" "private_egress" {
  count                  = length(aws_subnet.private.*.id)
  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.ngw[count.index].id
}

resource "aws_route_table_association" "basic_account_private" {
  count          = length(aws_subnet.private.*.id)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

# IAM
resource "aws_iam_role" "ec2_ssm" {
  name = "ec2_ssm"
  path = "/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.tags, { Name = "Basic SSM Access for EC2" })
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "ec2_ssm"
  role = aws_iam_role.ec2_ssm.name
  path = "/"

  tags = merge(var.tags, { Name = "Basic SSM Access for EC2" })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = data.aws_iam_policy.ssm.arn
}
