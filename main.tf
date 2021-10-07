# VPC

resource "aws_vpc" "basic_account" {
  cidr_block = "10.0.0.0/16"

  tags = var.tags # Add map
}

resource "aws_internet_gateway" "basic_account" {
  vpc_id = aws_vpc.basic_account.id

  tags = var.tags # Add map
}

resource "aws_subnet" "basic_account_public" {
  count                   = var.number_of_az
  vpc_id                  = aws_vpc.basic_account.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index % 2]

  depends_on = [aws_internet_gateway.basic_account]

  tags = merge(var.tags, { Name = "Public Subnet ${count.index}" })
}

resource "aws_subnet" "basic_account_private" {
  count                   = var.number_of_az
  vpc_id                  = aws_vpc.basic_account.id
  cidr_block              = "10.0.${count.index + length(aws_subnet.basic_account_public.*.id)}.0/24"
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[count.index % 2]

  tags = merge(var.tags, { Name = "Private Subnet ${count.index}" })
}

resource "aws_eip" "basic_account" {
  count = var.number_of_az
}

resource "aws_nat_gateway" "basic_account" {
  count         = var.number_of_az
  allocation_id = aws_eip.basic_account[count.index].id
  subnet_id     = aws_subnet.basic_account_public[count.index].id

  tags = var.tags

  depends_on = [aws_internet_gateway.basic_account]
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.basic_account.id

  tags = var.tags # Add map
}

resource "aws_route" "public_egress" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.basic_account.id
  depends_on             = [aws_route_table.public_route_table]
}

resource "aws_route_table_association" "basic_account_public" {
  count          = length(aws_subnet.basic_account_public.*.id)
  subnet_id      = aws_subnet.basic_account_public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  count  = length(aws_subnet.basic_account_private.*.id)
  vpc_id = aws_vpc.basic_account.id

  tags = var.tags # Add map
}

resource "aws_route" "private_egress" {
  count                  = length(aws_subnet.basic_account_private.*.id)
  route_table_id         = aws_route_table.private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.basic_account[count.index].id
}

resource "aws_route_table_association" "basic_account_private" {
  count          = length(aws_subnet.basic_account_private.*.id)
  subnet_id      = aws_subnet.basic_account_private[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
}

## Load Balancers
#
#resource "aws_lb" "basic_account" {
#  name            = "basic-accountalb"
#  internal        = false
#  security_groups = [aws_security_group.basic_account_alb.id]
#  subnets         = aws_subnet.basic_account_public.*.id
#
#  tags = var.tags # Add map
#}
#
#resource "aws_alb_listener" "basic_account_listener" {
#  load_balancer_arn = aws_lb.basic_account.arn
#  port              = 80
#  protocol          = "HTTP"
#
#  default_action {
#    target_group_arn = aws_lb_target_group.basic_account_target_group.arn
#    type             = "forward"
#  }
#}
#
#resource "aws_lb_target_group" "basic_account_target_group" {
#  name        = "basic-account-target-group"
#  port        = "80"
#  protocol    = "HTTP"
#  target_type = "instance"
#  vpc_id      = aws_vpc.basic_account.id
#
#  health_check {
#    healthy_threshold   = "3"
#    unhealthy_threshold = "3"
#    interval            = "30"
#    protocol            = "HTTP"
#    port                = "80"
#  }
#}
#
## Load Balancer Security Group
#resource "aws_security_group" "basic_account_alb" {
#  name        = "basic_account_alb"
#  description = "Security group for basic_account Application Load Balancers."
#  vpc_id      = aws_vpc.basic_account.id
#
#  tags = var.tags # Add map
#}
#
#resource "aws_security_group_rule" "basic_account_alb_egress" {
#  type              = "egress"
#  from_port         = 0
#  to_port           = 65535
#  protocol          = "-1"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.basic_account_alb.id
#}
#
#resource "aws_security_group_rule" "basic_account_alb_http" {
#  type              = "ingress"
#  from_port         = 80
#  to_port           = 80
#  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.basic_account_alb.id
#}
#
#
## Autoscaling - To Be Removed Later After Account
#
#resource "aws_placement_group" "basic_account" {
#  name     = "basic_account"
#  strategy = "spread"
#  tags     = var.tags
#}
#
#resource "aws_launch_configuration" "basic_account" {
#  name_prefix                 = "basic_account-"
#  image_id                    = data.aws_ami.debian-linux-11.id
#  instance_type               = var.ec2_type
#  iam_instance_profile        = aws_iam_instance_profile.basic_account.name
#  security_groups             = [aws_security_group.basic_account_ec2.id]
#  user_data                   = file("userdata.sh")
#  enable_monitoring           = "true"
#  associate_public_ip_address = "false"
#
#  root_block_device {
#    encrypted   = true
#    volume_size = 100
#  }
#
#  lifecycle {
#    create_before_destroy = "true"
#  }
#}
#
#resource "aws_autoscaling_group" "basic_account" {
#  name                      = "basic_account"
#  min_size                  = "2"
#  max_size                  = "8"
#  health_check_grace_period = "300"
#  health_check_type         = "ELB"
#  target_group_arns         = [aws_lb_target_group.basic_account_target_group.arn]
#  desired_capacity          = "2"
#  force_delete              = "true"
#  placement_group           = aws_placement_group.basic_account.id
#  launch_configuration      = aws_launch_configuration.basic_account.id
#  vpc_zone_identifier       = aws_subnet.basic_account_private.*.id
#  depends_on                = [aws_lb.basic_account]
#}
#
#
## EC2 Security Group
resource "aws_security_group" "basic_account_ec2" {
  name        = "basic_account_ec2"
  description = "Security group for basic_account ec2 instances."
  vpc_id      = aws_vpc.basic_account.id

  tags = var.tags # Add map
}

resource "aws_security_group_rule" "basic_account_ec2_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.basic_account_ec2.id
}

resource "aws_security_group_rule" "basic_account_ec2_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.basic_account_ec2.id
}

resource "aws_security_group_rule" "basic_account_ec2_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.basic_account_ec2.id
}

resource "aws_iam_instance_profile" "basic_account" {
  name = "basic_account"
  role = aws_iam_role.basic_account.name
  path = "/"
  tags = var.tags
}

resource "aws_iam_role" "basic_account" {
  name = "basic_account"
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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_account" {
  role       = aws_iam_role.basic_account.name
  policy_arn = data.aws_iam_policy.ssm.arn
}
